package com.ecommerce.listing.controller;

import com.ecommerce.listing.model.Product;
import com.ecommerce.listing.model.Product.ProductStatus;
import com.ecommerce.listing.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * REST controller for product operations.
 */
@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
@Slf4j
public class ProductController {

    private final ProductService productService;

    /**
     * Get all products with pagination.
     */
    @GetMapping
    public ResponseEntity<Page<Product>> getAllProducts(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        log.info("GET /api/v1/products - Fetching all products");
        return ResponseEntity.ok(productService.getAllProducts(pageable));
    }

    /**
     * Get a product by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        log.info("GET /api/v1/products/{} - Fetching product", id);
        return productService.getProductById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Get a product by SKU.
     */
    @GetMapping("/sku/{sku}")
    public ResponseEntity<Product> getProductBySku(@PathVariable String sku) {
        log.info("GET /api/v1/products/sku/{} - Fetching product by SKU", sku);
        return productService.getProductBySku(sku)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Create a new product.
     */
    @PostMapping
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        log.info("POST /api/v1/products - Creating new product: {}", product.getSku());
        Product createdProduct = productService.createProduct(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdProduct);
    }

    /**
     * Update an existing product.
     */
    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody Product product) {
        log.info("PUT /api/v1/products/{} - Updating product", id);
        Product updatedProduct = productService.updateProduct(id, product);
        return ResponseEntity.ok(updatedProduct);
    }

    /**
     * Delete a product.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        log.info("DELETE /api/v1/products/{} - Deleting product", id);
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Get products by category.
     */
    @GetMapping("/category/{categoryId}")
    public ResponseEntity<Page<Product>> getProductsByCategory(
            @PathVariable Long categoryId,
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/category/{} - Fetching products by category", categoryId);
        return ResponseEntity.ok(productService.getProductsByCategory(categoryId, pageable));
    }

    /**
     * Search products.
     */
    @GetMapping("/search")
    public ResponseEntity<Page<Product>> searchProducts(
            @RequestParam String query,
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/search - Searching products with query: {}", query);
        return ResponseEntity.ok(productService.searchProducts(query, pageable));
    }

    /**
     * Get available products.
     */
    @GetMapping("/available")
    public ResponseEntity<Page<Product>> getAvailableProducts(
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/available - Fetching available products");
        return ResponseEntity.ok(productService.getAvailableProducts(pageable));
    }

    /**
     * Get products by price range.
     */
    @GetMapping("/price-range")
    public ResponseEntity<Page<Product>> getProductsByPriceRange(
            @RequestParam BigDecimal minPrice,
            @RequestParam BigDecimal maxPrice,
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/price-range - Fetching products in range: {} - {}", minPrice, maxPrice);
        return ResponseEntity.ok(productService.getProductsByPriceRange(minPrice, maxPrice, pageable));
    }

    /**
     * Get products by brand.
     */
    @GetMapping("/brand/{brand}")
    public ResponseEntity<Page<Product>> getProductsByBrand(
            @PathVariable String brand,
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/brand/{} - Fetching products by brand", brand);
        return ResponseEntity.ok(productService.getProductsByBrand(brand, pageable));
    }

    /**
     * Get products by tag.
     */
    @GetMapping("/tag/{tag}")
    public ResponseEntity<Page<Product>> getProductsByTag(
            @PathVariable String tag,
            @PageableDefault(size = 20) Pageable pageable) {
        log.info("GET /api/v1/products/tag/{} - Fetching products by tag", tag);
        return ResponseEntity.ok(productService.getProductsByTag(tag, pageable));
    }

    /**
     * Update product status.
     */
    @PatchMapping("/{id}/status")
    public ResponseEntity<Void> updateProductStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> statusUpdate) {
        log.info("PATCH /api/v1/products/{}/status - Updating status", id);
        ProductStatus status = ProductStatus.valueOf(statusUpdate.get("status"));
        productService.updateProductStatus(id, status);
        return ResponseEntity.ok().build();
    }

    /**
     * Update product quantity.
     */
    @PatchMapping("/{id}/quantity")
    public ResponseEntity<Void> updateProductQuantity(
            @PathVariable Long id,
            @RequestBody Map<String, Integer> quantityUpdate) {
        log.info("PATCH /api/v1/products/{}/quantity - Updating quantity", id);
        int amount = quantityUpdate.get("amount");
        productService.updateProductQuantity(id, amount);
        return ResponseEntity.ok().build();
    }

    /**
     * Get low stock products.
     */
    @GetMapping("/low-stock")
    public ResponseEntity<List<Product>> getLowStockProducts(
            @RequestParam(defaultValue = "10") int threshold) {
        log.info("GET /api/v1/products/low-stock - Fetching low stock products with threshold: {}", threshold);
        return ResponseEntity.ok(productService.getLowStockProducts(threshold));
    }

    /**
     * Get products by multiple IDs.
     */
    @PostMapping("/batch")
    public ResponseEntity<List<Product>> getProductsByIds(@RequestBody List<Long> ids) {
        log.info("POST /api/v1/products/batch - Fetching products by IDs: {}", ids);
        return ResponseEntity.ok(productService.getProductsByIds(ids));
    }

    /**
     * Get featured products.
     */
    @GetMapping("/featured")
    public ResponseEntity<List<Product>> getFeaturedProducts(
            @PageableDefault(size = 10) Pageable pageable) {
        log.info("GET /api/v1/products/featured - Fetching featured products");
        return ResponseEntity.ok(productService.getFeaturedProducts(pageable));
    }

    /**
     * Check if SKU exists.
     */
    @GetMapping("/sku/{sku}/exists")
    public ResponseEntity<Map<String, Boolean>> checkSkuExists(@PathVariable String sku) {
        log.info("GET /api/v1/products/sku/{}/exists - Checking SKU existence", sku);
        boolean exists = productService.skuExists(sku);
        return ResponseEntity.ok(Map.of("exists", exists));
    }
}
