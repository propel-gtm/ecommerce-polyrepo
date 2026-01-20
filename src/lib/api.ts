const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  imageUrl?: string;
  category?: string;
  inStock: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface ProductsResponse {
  products: Product[];
  total: number;
  page: number;
  limit: number;
}

interface GetProductsOptions {
  limit?: number;
  page?: number;
  category?: string;
}

// Mock data for development when API is not available
const mockProducts: Product[] = [
  {
    id: '1',
    name: 'Wireless Headphones',
    description: 'High-quality wireless headphones with noise cancellation and long battery life.',
    price: 149.99,
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
    category: 'Electronics',
    inStock: true,
  },
  {
    id: '2',
    name: 'Leather Backpack',
    description: 'Stylish leather backpack perfect for work or travel.',
    price: 89.99,
    imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
    category: 'Accessories',
    inStock: true,
  },
  {
    id: '3',
    name: 'Smart Watch',
    description: 'Feature-packed smartwatch with health tracking and notifications.',
    price: 299.99,
    imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
    category: 'Electronics',
    inStock: true,
  },
  {
    id: '4',
    name: 'Running Shoes',
    description: 'Lightweight and comfortable running shoes for daily workouts.',
    price: 129.99,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
    category: 'Footwear',
    inStock: false,
  },
  {
    id: '5',
    name: 'Coffee Maker',
    description: 'Premium coffee maker for the perfect morning brew.',
    price: 79.99,
    imageUrl: 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=500',
    category: 'Home',
    inStock: true,
  },
  {
    id: '6',
    name: 'Desk Lamp',
    description: 'Modern LED desk lamp with adjustable brightness.',
    price: 49.99,
    imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=500',
    category: 'Home',
    inStock: true,
  },
];

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<T> {
  try {
    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      next: { revalidate: 60 }, // Cache for 60 seconds
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  } catch (error) {
    console.warn('API unavailable, using mock data:', error);
    throw error;
  }
}

export async function getProducts(options: GetProductsOptions = {}): Promise<Product[]> {
  const { limit, page = 1, category } = options;

  try {
    const params = new URLSearchParams();
    if (limit) params.append('limit', String(limit));
    if (page) params.append('page', String(page));
    if (category) params.append('category', category);

    const queryString = params.toString();
    const endpoint = `/api/products${queryString ? `?${queryString}` : ''}`;

    const data = await fetchApi<ProductsResponse | Product[]>(endpoint);

    // Handle both array response and paginated response
    if (Array.isArray(data)) {
      return limit ? data.slice(0, limit) : data;
    }

    return data.products;
  } catch {
    // Return mock data when API is unavailable
    let products = [...mockProducts];

    if (category) {
      products = products.filter((p) => p.category === category);
    }

    if (limit) {
      products = products.slice(0, limit);
    }

    return products;
  }
}

export async function getProduct(id: string): Promise<Product | null> {
  try {
    return await fetchApi<Product>(`/api/products/${id}`);
  } catch {
    // Return mock product when API is unavailable
    const product = mockProducts.find((p) => p.id === id);
    return product || null;
  }
}

export async function getCategories(): Promise<string[]> {
  try {
    return await fetchApi<string[]>('/api/categories');
  } catch {
    // Return mock categories when API is unavailable
    const categories = Array.from(new Set(mockProducts.map((p) => p.category).filter(Boolean)));
    return categories as string[];
  }
}
