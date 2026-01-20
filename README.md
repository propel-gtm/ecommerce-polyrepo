# E-commerce Frontend (Next.js)

A minimal Next.js 14 ecommerce frontend with App Router, TypeScript, and Tailwind CSS.

## Tech Stack

- Next.js 14 (App Router)
- React 18
- TypeScript
- Tailwind CSS

## Getting Started

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy environment variables:
   ```bash
   cp .env.example .env.local
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000)

## Project Structure

```
src/
  app/
    layout.tsx      # Root layout
    page.tsx        # Home page
    products/
      page.tsx      # Product listing
      [id]/
        page.tsx    # Product detail
  components/
    Header.tsx      # Navigation header
    ProductCard.tsx # Product card component
  lib/
    api.ts          # API client
```

## Environment Variables

- `NEXT_PUBLIC_API_URL` - Backend API URL (default: http://localhost:8080)
