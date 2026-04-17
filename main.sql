CREATE TABLE IF NOT EXISTS OutboxEvents (
    event_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    aggregate_type VARCHAR(50),
    aggregate_id INT,
    payload JSON,
    is_processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

CREATE PROCEDURE GenerateOrderEvent(IN p_order_id INT)
BEGIN
    INSERT INTO OutboxEvents (aggregate_type, aggregate_id, payload)
    SELECT 
        'ORDER_CREATED',
        o.order_id,
        JSON_OBJECT(
            'customer_id', o.cust_id,
            'amount', o.total_amount,
            'timestamp', o.order_date,
            'items_count', (SELECT COUNT(*) FROM OrderDetails WHERE order_id = p_order_id)
        )
    FROM Orders o
    WHERE o.order_id = p_order_id;
END //

DELIMITER ;

-- Cleanup Procedure for Processed Events
CREATE PROCEDURE PurgeProcessedEvents()
BEGIN
    DELETE FROM OutboxEvents 
    WHERE is_processed = TRUE 
    AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
END //
