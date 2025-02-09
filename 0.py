#!/usr/bin/env python3
"""
ondo_crawler.py

Recursively crawls ondo.finance (or ondo.foundation) up to a given depth,
extracting:
  1. All URLs referencing ondo.finance/foundation
  2. API endpoints referencing segments like /public/v1/, /api/, /query/, /submit/
  3. Also parses JS chunks as text to find relative paths like /public/v1/... not in <a> or <script> tags

Usage:
  python ondo_crawler.py [start_url] [max_depth] [concurrency]

Dependencies: aiohttp, beautifulsoup4, lxml, uvloop (optional)
"""

import asyncio
import aiohttp
import re
import sys
from datetime import datetime
from bs4 import BeautifulSoup
from urllib.parse import urlparse, urljoin

# Attempt higher-performance event loop if uvloop is installed
try:
    import uvloop
    uvloop.install()
except ImportError:
    pass

# Regex to capture absolute OnDo URLs: https://ondo.finance/path...
ONDO_ABSOLUTE_PATTERN = re.compile(
    r'(https?://(?:ondo\.finance|ondo\.foundation)[^"\'\s<>]+)',
    re.IGNORECASE
)

# Regex to capture relative API paths: /public/v1/..., /api/..., /query/..., /submit/...
# Example matches: /public/v1/query/get_api_key
#                 /api/whatever
#                 /submit/create_users
API_SEGMENTS = ("public/v1", "api", "query", "submit")
SEGMENT_PATTERN = re.compile(
    r'(/(?:public/v1|api|query|submit)[^"\'\s<>]*)',
    re.IGNORECASE
)

def extract_urls_from_text(text: str) -> set:
    """
    Extract all absolute OnDo URLs in text, e.g. https://ondo.finance/foo
    """
    return set(ONDO_ABSOLUTE_PATTERN.findall(text))

def extract_relative_api_paths(text: str) -> set:
    """
    Extract lines that match relative endpoints like /public/v1/... or /api/...
    """
    return set(SEGMENT_PATTERN.findall(text))

def extract_internal_links(html: str, base_url: str) -> set:
    """
    Parse HTML anchor tags <a href="...">,
    convert to absolute URLs, keep only ondo.finance or ondo.foundation.
    """
    soup = BeautifulSoup(html, "lxml")
    links = set()
    for tag in soup.find_all("a", href=True):
        href = tag["href"].strip()
        absolute = urljoin(base_url, href)
        parsed = urlparse(absolute)
        if "ondo.finance" in parsed.netloc or "ondo.foundation" in parsed.netloc:
            links.add(absolute)
    return links

def extract_script_srcs(html: str, base_url: str) -> set:
    """
    Grab script src attributes, convert to absolute URLs if relative,
    keep them if they're on ondo.finance or ondo.foundation.
    """
    soup = BeautifulSoup(html, "lxml")
    srcs = set()
    for tag in soup.find_all("script", src=True):
        src = tag["src"].strip()
        absolute = urljoin(base_url, src)
        parsed = urlparse(absolute)
        if "ondo.finance" in parsed.netloc or "ondo.foundation" in parsed.netloc:
            srcs.add(absolute)
    return srcs

async def fetch_text(url: str, session: aiohttp.ClientSession) -> str:
    """Fetch the URL content as text (HTML or JS)."""
    try:
        async with session.get(url) as resp:
            resp.raise_for_status()
            return await resp.text()
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return ""

async def worker(
    worker_name: str,
    session: aiohttp.ClientSession,
    queue: asyncio.Queue,
    visited: set,
    all_urls: set,
    api_urls: set,
    max_depth: int
):
    """
    Asynchronous worker:
     - pulls (url, depth) from the queue
     - fetches text
     - extracts absolute ondo URLs, plus relative API references
     - reconstructs relative references into absolute
     - adds new links to the queue
    """
    while True:
        try:
            url, depth = await queue.get()
        except asyncio.CancelledError:
            break

        if url in visited or depth > max_depth:
            queue.task_done()
            continue

        visited.add(url)
        print(f"[{worker_name}] Crawling: {url} (depth {depth})")

        text = await fetch_text(url, session)
        if not text:
            queue.task_done()
            continue

        # 1) Find absolute OnDo URLs:
        found_abs = extract_urls_from_text(text)

        # 2) Find relative API references:
        found_rel = extract_relative_api_paths(text)

        # Add these to "all_urls", reconstructing them as absolute if needed
        for abs_url in found_abs:
            all_urls.add(abs_url)
            if any(seg in abs_url for seg in API_SEGMENTS):
                api_urls.add(abs_url)

        # For each relative match, reconstruct full URL using the domain of current page:
        parsed = urlparse(url)
        base = f"{parsed.scheme}://{parsed.netloc}"
        for rel_path in found_rel:
            full_url = urljoin(base, rel_path)
            all_urls.add(full_url)
            if any(seg in full_url for seg in API_SEGMENTS):
                api_urls.add(full_url)

        # 3) Also parse HTML to discover new internal links:
        new_links = extract_internal_links(text, url)
        # 4) Parse script src=... for more .js files
        new_links |= extract_script_srcs(text, url)

        # Add new links to the queue
        for link in new_links:
            if link not in visited:
                await queue.put((link, depth + 1))

        queue.task_done()

async def crawl_domain(start_url: str, max_depth: int, concurrency: int):
    """
    Sets up an asyncio queue, spawns worker tasks, and crawls up to max_depth.
    """
    visited = set()
    all_urls = set()
    api_urls = set()

    queue = asyncio.Queue()
    await queue.put((start_url, 0))

    async with aiohttp.ClientSession() as session:
        tasks = []
        for i in range(concurrency):
            t = asyncio.create_task(worker(
                f"Worker-{i+1}",
                session,
                queue,
                visited,
                all_urls,
                api_urls,
                max_depth
            ))
            tasks.append(t)

        # Wait until queue is empty
        await queue.join()

        # Cancel all tasks
        for t in tasks:
            t.cancel()

        await asyncio.gather(*tasks, return_exceptions=True)

    return all_urls, api_urls

async def main():
    start_url = sys.argv[1] if len(sys.argv) > 1 else "https://ondo.finance"
    max_depth = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    concurrency = int(sys.argv[3]) if len(sys.argv) > 3 else 10

    print(f"Starting crawl at {start_url}, depth={max_depth}, concurrency={concurrency}...")
    all_urls, api_urls = await crawl_domain(start_url, max_depth, concurrency)

    timestamp = datetime.now().isoformat(timespec="seconds")
    safe_ts = timestamp.replace(":", "-")
    output_file = f"ondo_crawler_results_{safe_ts}.txt"

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(f"Timestamp: {timestamp}\n\n")
        f.write("=== API Endpoints ===\n")
        if api_urls:
            for url in sorted(api_urls):
                f.write(url + "\n")
        else:
            f.write("None found.\n")

        f.write("\n=== All OnDo URLs ===\n")
        if all_urls:
            for url in sorted(all_urls):
                f.write(url + "\n")
        else:
            f.write("None found.\n")

    print(f"\nDone. Results in {output_file}")

if __name__ == "__main__":
    asyncio.run(main())
