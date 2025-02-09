/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true
  },
  trailingSlash: true,
  assetPrefix: '',
  basePath: '',
  experimental: {
    images: {
      unoptimized: true
    }
  }
}

module.exports = nextConfig