#!/usr/bin/env python3
"""
ondo_crawler.py

This script recursively crawls a target ondo domain (default: https://ondo.finance) up to a specified depth.
It extracts:
  1. All URLs that reference ondo.finance or ondo.foundation.
  2. API endpoints (those URLs containing segments like "/public/v1/", "/api/", "/query/", or "/submit/").

It uses asyncio with an asynchronous Queue and worker tasks to scale and crawl deeper.
Results are printed to the terminal and saved in a timestamped text file.

Usage:
    chmod +x ondo_crawler.py
    ./ondo_crawler.py [start_url] [max_depth] [concurrency]

Examples:
    ./ondo_crawler.py
    ./ondo_crawler.py https://ondo.finance 4 10
"""

import asyncio
import aiohttp
import re
import sys
from datetime import datetime
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

# Use uvloop for higher performance, if available.
try:
    import uvloop
    uvloop.install()
except ImportError:
    pass

# Pattern to match any URL referencing ondo.finance or ondo.foundation.
ONDO_PATTERN = re.compile(
    r'(https?://(?:ondo\.finance|ondo\.foundation)[^"\'\s<>]+)',
    re.IGNORECASE
)

def extract_urls_from_text(text: str) -> set:
    """Extract ondo URLs from a text block using a regex."""
    return set(ONDO_PATTERN.findall(text))

def extract_internal_links(html: str, base_url: str) -> set:
    """Extract internal anchor links (converted to absolute URLs) from HTML."""
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
    """Extract script tag src attributes from HTML and convert them to absolute URLs."""
    soup = BeautifulSoup(html, "lxml")
    srcs = set()
    for tag in soup.find_all("script", src=True):
        src = tag["src"].strip()
        absolute = urljoin(base_url, src)
        srcs.add(absolute)
    return srcs

async def fetch_text(url: str, session: aiohttp.ClientSession) -> str:
    """Fetch text content from a URL."""
    try:
        async with session.get(url) as response:
            response.raise_for_status()
            return await response.text()
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return ""

async def worker(name: str, session: aiohttp.ClientSession, queue: asyncio.Queue,
                 visited: set, all_urls: set, api_urls: set, max_depth: int):
    """Worker coroutine that processes URLs from the queue."""
    while True:
        try:
            url, depth = await queue.get()
        except asyncio.CancelledError:
            break
        if url in visited or depth > max_depth:
            queue.task_done()
            continue
        visited.add(url)
        print(f"[{name}] Crawling: {url} (depth {depth})")
        text = await fetch_text(url, session)
        if not text:
            queue.task_done()
            continue

        # Extract ondo URLs from the page text.
        found = extract_urls_from_text(text)
        all_urls.update(found)
        # Flag API endpoints (adjust segments as needed).
        for u in found:
            if any(seg in u for seg in ("/public/v1/", "/api/", "/query/", "/submit/")):
                api_urls.add(u)

        # Extract internal links and script sources.
        new_links = extract_internal_links(text, url)
        new_links |= extract_script_srcs(text, url)
        for link in new_links:
            if link not in visited:
                await queue.put((link, depth + 1))
        queue.task_done()

async def crawl_domain(start_url: str, max_depth: int, concurrency: int) -> (set, set):
    """Crawl the domain starting from start_url up to max_depth with given concurrency."""
    visited = set()
    all_urls = set()
    api_urls = set()
    queue = asyncio.Queue()
    await queue.put((start_url, 0))

    async with aiohttp.ClientSession() as session:
        tasks = []
        for i in range(concurrency):
            task = asyncio.create_task(worker(f"Worker-{i+1}", session, queue, visited, all_urls, api_urls, max_depth))
            tasks.append(task)

        await queue.join()
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
    return all_urls, api_urls

async def main():
    # Command-line arguments: start_url, max_depth, and concurrency.
    start_url = sys.argv[1] if len(sys.argv) > 1 else "https://ondo.finance"
    max_depth = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    concurrency = int(sys.argv[3]) if len(sys.argv) > 3 else 10

    print(f"Starting crawl at {start_url} with max_depth={max_depth} and concurrency={concurrency}")

    all_urls, api_urls = await crawl_domain(start_url, max_depth, concurrency)

    timestamp = datetime.now().isoformat(timespec="seconds")
    safe_ts = timestamp.replace(":", "-")
    output_filename = f"ondo_crawler_results_{safe_ts}.txt"

    with open(output_filename, "w", encoding="utf-8") as f:
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

    print(f"\nCrawling complete. Results saved to {output_filename}")

if __name__ == "__main__":
    asyncio.run(main())
