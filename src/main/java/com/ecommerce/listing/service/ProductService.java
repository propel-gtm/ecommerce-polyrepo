package com.ecommerce.listing.service;

import com.ecommerce.listing.model.Category;
import com.ecommerce.listing.model.Product;
import com.ecommerce.listing.model.Product.ProductStatus;
import com.ecommerce.listing.repository.ProductRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Service layer for product operations.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;

    /**
     * Get all products with pagination.
     */
    public Page<Product> getAllProducts(Pageable pageable) {
        log.debug("Fetching all products with pagination: {}", pageable);
        return productRepository.findAll(pageable);
    }

    /**
     * Get a product by ID.
     */
    public Optional<Product> getProductById(Long id) {
        log.debug("Fetching product by ID: {}", id);
        return productRepository.findById(id);
    }

    /**
     * Get a product by ID or throw exception.
     */
    public Product getProductByIdOrThrow(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with ID: " + id));
    }

    /**
     * Get a product by SKU.
     */
    public Optional<Product> getProductBySku(String sku) {
        log.debug("Fetching product by SKU: {}", sku);
        return productRepository.findBySku(sku);
    }

    /**
     * Create a new product.
     */
    @Transactional
    public Product createProduct(Product product) {
        log.info("Creating new product with SKU: {}", product.getSku());

        if (productRepository.existsBySku(product.getSku())) {
            throw new IllegalArgumentException("Product with SKU already exists: " + product.getSku());
        }

        return productRepository.save(product);
    }

    /**
     * Update an existing product.
     */
    @Transactional
    public Product updateProduct(Long id, Product productDetails) {
        log.info("Updating product with ID: {}", id);

        Product existingProduct = getProductByIdOrThrow(id);

        // Update fields
        existingProduct.setName(productDetails.getName());
        existingProduct.setDescription(productDetails.getDescription());
        existingProduct.setPrice(productDetails.getPrice());
        existingProduct.setQuantity(productDetails.getQuantity());
        existingProduct.setCategory(productDetails.getCategory());
        existingProduct.setImageUrls(productDetails.getImageUrls());
        existingProduct.setStatus(productDetails.getStatus());
        existingProduct.setBrand(productDetails.getBrand());
        existingProduct.setWeight(productDetails.getWeight());
        existingProduct.setTags(productDetails.getTags());

        return productRepository.save(existingProduct);
    }

    /**
     * Delete a product.
     */
    @Transactional
    public void deleteProduct(Long id) {
        log.info("Deleting product with ID: {}", id);

        if (!productRepository.existsById(id)) {
            throw new EntityNotFoundException("Product not found with ID: " + id);
        }

        productRepository.deleteById(id);
    }

    /**
     * Get products by category.
     */
    public Page<Product> getProductsByCategory(Long categoryId, Pageable pageable) {
        log.debug("Fetching products for category ID: {}", categoryId);
        return productRepository.findByCategoryId(categoryId, pageable);
    }

    /**
     * Search products by query.
     */
    public Page<Product> searchProducts(String query, Pageable pageable) {
        log.debug("Searching products with query: {}", query);
        return productRepository.searchProducts(query, pageable);
    }

    /**
     * Get available products.
     */
    public Page<Product> getAvailableProducts(Pageable pageable) {
        log.debug("Fetching available products");
        return productRepository.findAllAvailable(pageable);
    }

    /**
     * Get products by price range.
     */
    public Page<Product> getProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice, Pageable pageable) {
        log.debug("Fetching products in price range: {} - {}", minPrice, maxPrice);
        return productRepository.findByPriceRange(minPrice, maxPrice, pageable);
    }

    /**
     * Get products by brand.
     */
    public Page<Product> getProductsByBrand(String brand, Pageable pageable) {
        log.debug("Fetching products by brand: {}", brand);
        return productRepository.findByBrandIgnoreCase(brand, pageable);
    }

    /**
     * Get products by tag.
     */
    public Page<Product> getProductsByTag(String tag, Pageable pageable) {
        log.debug("Fetching products by tag: {}", tag);
        return productRepository.findByTag(tag, pageable);
    }

    /**
     * Update product status.
     */
    @Transactional
    public void updateProductStatus(Long productId, ProductStatus status) {
        log.info("Updating status for product ID {} to {}", productId, status);

        int updated = productRepository.updateStatus(productId, status);
        if (updated == 0) {
            throw new EntityNotFoundException("Product not found with ID: " + productId);
        }
    }

    /**
     * Update product quantity.
     */
    @Transactional
    public void updateProductQuantity(Long productId, int amount) {
        log.info("Updating quantity for product ID {} by {}", productId, amount);

        Product product = getProductByIdOrThrow(productId);
        if (amount < 0 && product.getQuantity() + amount < 0) {
            throw new IllegalArgumentException("Insufficient quantity for product: " + productId);
        }

        productRepository.updateQuantity(productId, amount);
    }

    /**
     * Get low stock products.
     */
    public List<Product> getLowStockProducts(int threshold) {
        log.debug("Fetching low stock products with threshold: {}", threshold);
        return productRepository.findLowStockProducts(threshold);
    }

    /**
     * Get products by multiple IDs.
     */
    public List<Product> getProductsByIds(List<Long> ids) {
        log.debug("Fetching products by IDs: {}", ids);
        return productRepository.findByIdIn(ids);
    }

    /**
     * Get featured products.
     */
    public List<Product> getFeaturedProducts(Pageable pageable) {
        log.debug("Fetching featured products");
        return productRepository.findFeaturedProducts(pageable);
    }

    /**
     * Check if SKU exists.
     */
    public boolean skuExists(String sku) {
        return productRepository.existsBySku(sku);
    }

    /**
     * Count products by category.
     */
    public long countProductsByCategory(Long categoryId) {
        return productRepository.countByCategoryId(categoryId);
    }

    /**
     * Count products by status.
     */
    public long countProductsByStatus(ProductStatus status) {
        return productRepository.countByStatus(status);
    }
}
