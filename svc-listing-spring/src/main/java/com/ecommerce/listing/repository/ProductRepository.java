package com.ecommerce.listing.repository;

import com.ecommerce.listing.model.Product;
import com.ecommerce.listing.model.Product.ProductStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Repository interface for Product entity operations.
 */
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    /**
     * Find a product by its SKU.
     */
    Optional<Product> findBySku(String sku);

    /**
     * Check if a product exists with the given SKU.
     */
    boolean existsBySku(String sku);

    /**
     * Find all products in a specific category.
     */
    Page<Product> findByCategoryId(Long categoryId, Pageable pageable);

    /**
     * Find all products with a specific status.
     */
    Page<Product> findByStatus(ProductStatus status, Pageable pageable);

    /**
     * Find all active products.
     */
    @Query("SELECT p FROM Product p WHERE p.status = 'ACTIVE' AND p.quantity > 0")
    Page<Product> findAllAvailable(Pageable pageable);

    /**
     * Search products by name or description.
     */
    @Query("SELECT p FROM Product p WHERE " +
           "LOWER(p.name) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Product> searchProducts(@Param("query") String query, Pageable pageable);

    /**
     * Find products within a price range.
     */
    @Query("SELECT p FROM Product p WHERE p.price BETWEEN :minPrice AND :maxPrice AND p.status = 'ACTIVE'")
    Page<Product> findByPriceRange(
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice,
            Pageable pageable);

    /**
     * Find products by brand.
     */
    Page<Product> findByBrandIgnoreCase(String brand, Pageable pageable);

    /**
     * Find products containing a specific tag.
     */
    @Query("SELECT p FROM Product p JOIN p.tags t WHERE LOWER(t) = LOWER(:tag)")
    Page<Product> findByTag(@Param("tag") String tag, Pageable pageable);

    /**
     * Find low stock products (quantity below threshold).
     */
    @Query("SELECT p FROM Product p WHERE p.quantity <= :threshold AND p.status = 'ACTIVE'")
    List<Product> findLowStockProducts(@Param("threshold") int threshold);

    /**
     * Update product quantity.
     */
    @Modifying
    @Query("UPDATE Product p SET p.quantity = p.quantity + :amount WHERE p.id = :productId")
    int updateQuantity(@Param("productId") Long productId, @Param("amount") int amount);

    /**
     * Update product status.
     */
    @Modifying
    @Query("UPDATE Product p SET p.status = :status WHERE p.id = :productId")
    int updateStatus(@Param("productId") Long productId, @Param("status") ProductStatus status);

    /**
     * Find products by multiple IDs.
     */
    List<Product> findByIdIn(List<Long> ids);

    /**
     * Count products by category.
     */
    long countByCategoryId(Long categoryId);

    /**
     * Count products by status.
     */
    long countByStatus(ProductStatus status);

    /**
     * Find featured products (could be based on tags or a dedicated field).
     */
    @Query("SELECT p FROM Product p JOIN p.tags t WHERE t = 'featured' AND p.status = 'ACTIVE'")
    List<Product> findFeaturedProducts(Pageable pageable);
}
