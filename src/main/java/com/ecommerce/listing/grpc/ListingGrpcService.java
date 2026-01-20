package com.ecommerce.listing.grpc;

import com.ecommerce.listing.model.Product;
import com.ecommerce.listing.model.Product.ProductStatus;
import com.ecommerce.listing.service.ProductService;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.service.GrpcService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

import java.math.BigDecimal;
import java.util.List;

/**
 * gRPC service implementation for listing operations.
 *
 * Note: This is a skeleton implementation. In a real project, you would generate
 * the gRPC stubs from a .proto file and extend the generated base class.
 *
 * Example proto definition would be:
 *
 * service ListingService {
 *   rpc GetProduct (GetProductRequest) returns (ProductResponse);
 *   rpc ListProducts (ListProductsRequest) returns (ListProductsResponse);
 *   rpc CreateProduct (CreateProductRequest) returns (ProductResponse);
 *   rpc UpdateProduct (UpdateProductRequest) returns (ProductResponse);
 *   rpc DeleteProduct (DeleteProductRequest) returns (DeleteProductResponse);
 *   rpc SearchProducts (SearchProductsRequest) returns (ListProductsResponse);
 *   rpc GetProductsByCategory (GetProductsByCategoryRequest) returns (ListProductsResponse);
 *   rpc UpdateProductQuantity (UpdateQuantityRequest) returns (ProductResponse);
 * }
 *
 * @GrpcService annotation is commented out because this is a skeleton implementation
 * without actual proto-generated stubs. Enable it once proper gRPC implementation is added.
 */
// @GrpcService
@RequiredArgsConstructor
@Slf4j
public class ListingGrpcService {

    private final ProductService productService;

    /**
     * Get a single product by ID.
     *
     * In a real implementation with generated stubs:
     * public void getProduct(GetProductRequest request, StreamObserver<ProductResponse> responseObserver)
     */
    public Product getProduct(Long productId) {
        log.info("gRPC getProduct called for ID: {}", productId);

        try {
            return productService.getProductByIdOrThrow(productId);
        } catch (EntityNotFoundException e) {
            log.error("Product not found: {}", productId);
            throw e;
        }
    }

    /**
     * Get a single product by SKU.
     */
    public Product getProductBySku(String sku) {
        log.info("gRPC getProductBySku called for SKU: {}", sku);

        return productService.getProductBySku(sku)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with SKU: " + sku));
    }

    /**
     * List products with pagination.
     *
     * In a real implementation with generated stubs:
     * public void listProducts(ListProductsRequest request, StreamObserver<ListProductsResponse> responseObserver)
     */
    public Page<Product> listProducts(int page, int size, String sortBy, String sortDirection) {
        log.info("gRPC listProducts called - page: {}, size: {}", page, size);

        Sort.Direction direction = Sort.Direction.fromString(sortDirection);
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortBy));

        return productService.getAllProducts(pageRequest);
    }

    /**
     * Create a new product.
     *
     * In a real implementation with generated stubs:
     * public void createProduct(CreateProductRequest request, StreamObserver<ProductResponse> responseObserver)
     */
    public Product createProduct(String sku, String name, String description,
                                  BigDecimal price, int quantity, Long categoryId,
                                  List<String> imageUrls, String brand, List<String> tags) {
        log.info("gRPC createProduct called for SKU: {}", sku);

        Product product = Product.builder()
                .sku(sku)
                .name(name)
                .description(description)
                .price(price)
                .quantity(quantity)
                .imageUrls(imageUrls)
                .brand(brand)
                .tags(tags)
                .status(ProductStatus.DRAFT)
                .build();

        return productService.createProduct(product);
    }

    /**
     * Update an existing product.
     *
     * In a real implementation with generated stubs:
     * public void updateProduct(UpdateProductRequest request, StreamObserver<ProductResponse> responseObserver)
     */
    public Product updateProduct(Long productId, String name, String description,
                                  BigDecimal price, int quantity, String status,
                                  List<String> imageUrls, String brand, List<String> tags) {
        log.info("gRPC updateProduct called for ID: {}", productId);

        Product existingProduct = productService.getProductByIdOrThrow(productId);

        existingProduct.setName(name);
        existingProduct.setDescription(description);
        existingProduct.setPrice(price);
        existingProduct.setQuantity(quantity);
        existingProduct.setStatus(ProductStatus.valueOf(status));
        existingProduct.setImageUrls(imageUrls);
        existingProduct.setBrand(brand);
        existingProduct.setTags(tags);

        return productService.updateProduct(productId, existingProduct);
    }

    /**
     * Delete a product.
     *
     * In a real implementation with generated stubs:
     * public void deleteProduct(DeleteProductRequest request, StreamObserver<DeleteProductResponse> responseObserver)
     */
    public void deleteProduct(Long productId) {
        log.info("gRPC deleteProduct called for ID: {}", productId);
        productService.deleteProduct(productId);
    }

    /**
     * Search products.
     *
     * In a real implementation with generated stubs:
     * public void searchProducts(SearchProductsRequest request, StreamObserver<ListProductsResponse> responseObserver)
     */
    public Page<Product> searchProducts(String query, int page, int size) {
        log.info("gRPC searchProducts called with query: {}", query);

        PageRequest pageRequest = PageRequest.of(page, size);
        return productService.searchProducts(query, pageRequest);
    }

    /**
     * Get products by category.
     *
     * In a real implementation with generated stubs:
     * public void getProductsByCategory(GetProductsByCategoryRequest request, StreamObserver<ListProductsResponse> responseObserver)
     */
    public Page<Product> getProductsByCategory(Long categoryId, int page, int size) {
        log.info("gRPC getProductsByCategory called for category: {}", categoryId);

        PageRequest pageRequest = PageRequest.of(page, size);
        return productService.getProductsByCategory(categoryId, pageRequest);
    }

    /**
     * Update product quantity.
     *
     * In a real implementation with generated stubs:
     * public void updateProductQuantity(UpdateQuantityRequest request, StreamObserver<ProductResponse> responseObserver)
     */
    public Product updateProductQuantity(Long productId, int amount) {
        log.info("gRPC updateProductQuantity called for ID: {} with amount: {}", productId, amount);

        productService.updateProductQuantity(productId, amount);
        return productService.getProductByIdOrThrow(productId);
    }

    /**
     * Get available products.
     */
    public Page<Product> getAvailableProducts(int page, int size) {
        log.info("gRPC getAvailableProducts called");

        PageRequest pageRequest = PageRequest.of(page, size);
        return productService.getAvailableProducts(pageRequest);
    }

    /**
     * Get products by price range.
     */
    public Page<Product> getProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice, int page, int size) {
        log.info("gRPC getProductsByPriceRange called: {} - {}", minPrice, maxPrice);

        PageRequest pageRequest = PageRequest.of(page, size);
        return productService.getProductsByPriceRange(minPrice, maxPrice, pageRequest);
    }

    /**
     * Batch get products by IDs.
     */
    public List<Product> getProductsByIds(List<Long> productIds) {
        log.info("gRPC getProductsByIds called for {} products", productIds.size());
        return productService.getProductsByIds(productIds);
    }

    /**
     * Update product status.
     */
    public void updateProductStatus(Long productId, String status) {
        log.info("gRPC updateProductStatus called for ID: {} with status: {}", productId, status);
        productService.updateProductStatus(productId, ProductStatus.valueOf(status));
    }
}
