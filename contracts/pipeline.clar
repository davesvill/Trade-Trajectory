;; Trade-Trajectory Transparency Platform
;; Enables manufacturers to track and verify product authenticity throughout the supply chain

;; Error definitions
(define-constant ERR-ACCESS-DENIED (err u300))
(define-constant ERR-MANUFACTURER-EXISTS (err u301))
(define-constant ERR-PRODUCT-NOT-EXISTS (err u302))
(define-constant ERR-UNSUPPORTED-CATEGORY (err u303))
(define-constant ERR-PRODUCT-RECALLED (err u304))
(define-constant ERR-BATCH-EXPIRED (err u305))
(define-constant ERR-INVALID-PARAMETERS (err u306))
(define-constant ERR-ZERO-PRINCIPAL (err u307))
(define-constant ERR-INVALID-TIME-SPAN (err u308))
(define-constant ERR-PRODUCT-EXISTS (err u309))
(define-constant ERR-INVALID-BATCH-CODE (err u310))

;; Data structures
(define-map certified-manufacturers
    principal 
    {
        company-title: (string-ascii 50),
        company-domain: (string-ascii 100),
        certification-active: bool
    }
)

(define-map product-batches
    {batch-identifier: (string-ascii 50), manufacturer-principal: principal}
    {
        producing-facility: principal,
        production-block: uint,
        shelf-life-block: uint,
        product-category: (string-ascii 50),
        batch-hash-code: (buff 32),
        supply-chain-notes: (string-ascii 256),
        recall-status: bool
    }
)

(define-map product-categories
    (string-ascii 50)
    {
        category-specification: (string-ascii 100),
        shelf-life-blocks: uint
    }
)

;; System control
(define-data-var platform-owner principal tx-sender)

;; Input validation functions
(define-private (check-principal-validity (addr principal))
    (and 
        (not (is-eq addr (as-contract tx-sender)))
        (not (is-eq addr 'SP000000000000000000002Q6VF78)))
)

(define-private (check-time-validity (time-blocks uint))
    (> time-blocks u0)
)

(define-private (check-string-validity (input (string-ascii 256)))
    (not (is-eq input ""))
)

(define-private (check-batch-code-validity (code (buff 32)))
    (and 
        (not (is-eq code 0x))
        (is-eq (len code) u32))
)

;; Platform management functions
(define-public (update-platform-owner (new-owner-principal principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-owner)) ERR-ACCESS-DENIED)
        (asserts! (check-principal-validity new-owner-principal) ERR-ZERO-PRINCIPAL)
        (ok (var-set platform-owner new-owner-principal))
    )
)

(define-public (register-manufacturer 
    (company-title (string-ascii 50)) 
    (company-domain (string-ascii 100))
)
    (let (
        (manufacturer-record {
            company-title: company-title, 
            company-domain: company-domain, 
            certification-active: false
        })
    )
        (asserts! (check-string-validity company-title) ERR-INVALID-PARAMETERS)
        (asserts! (check-string-validity company-domain) ERR-INVALID-PARAMETERS)
        (asserts! (is-none (map-get? certified-manufacturers tx-sender)) ERR-MANUFACTURER-EXISTS)
        (ok (map-set certified-manufacturers tx-sender manufacturer-record))
    )
)

(define-public (certify-manufacturer (manufacturer-principal principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-owner)) ERR-ACCESS-DENIED)
        (asserts! (check-principal-validity manufacturer-principal) ERR-ZERO-PRINCIPAL)
        (asserts! (is-some (map-get? certified-manufacturers manufacturer-principal)) ERR-PRODUCT-NOT-EXISTS)
        (ok (map-set certified-manufacturers 
            manufacturer-principal 
            (merge (unwrap-panic (map-get? certified-manufacturers manufacturer-principal)) 
                {certification-active: true}
            )
        ))
    )
)

(define-public (define-product-category 
    (category-name (string-ascii 50)) 
    (category-specification (string-ascii 100)) 
    (shelf-life-blocks uint)
)
    (begin
        (asserts! (is-eq tx-sender (var-get platform-owner)) ERR-ACCESS-DENIED)
        (asserts! (check-string-validity category-name) ERR-INVALID-PARAMETERS)
        (asserts! (check-string-validity category-specification) ERR-INVALID-PARAMETERS)
        (asserts! (check-time-validity shelf-life-blocks) ERR-INVALID-TIME-SPAN)
        (ok (map-set product-categories category-name {
            category-specification: category-specification,
            shelf-life-blocks: shelf-life-blocks
        }))
    )
)

(define-public (create-product-batch
    (batch-identifier (string-ascii 50))
    (manufacturer-principal principal)
    (product-category (string-ascii 50))
    (batch-hash-code (buff 32))
    (supply-chain-notes (string-ascii 256))
)
    (let (
        (manufacturer-record (unwrap! (map-get? certified-manufacturers tx-sender) ERR-PRODUCT-NOT-EXISTS))
        (category-record (unwrap! (map-get? product-categories product-category) ERR-UNSUPPORTED-CATEGORY))
        (current-block-height block-height)
        (expiration-block-height (+ current-block-height (get shelf-life-blocks category-record)))
    )
        (asserts! (check-string-validity batch-identifier) ERR-INVALID-PARAMETERS)
        (asserts! (check-principal-validity manufacturer-principal) ERR-ZERO-PRINCIPAL)
        (asserts! (check-string-validity product-category) ERR-INVALID-PARAMETERS)
        (asserts! (check-string-validity supply-chain-notes) ERR-INVALID-PARAMETERS)
        (asserts! (check-batch-code-validity batch-hash-code) ERR-INVALID-BATCH-CODE)
        (asserts! (get certification-active manufacturer-record) ERR-ACCESS-DENIED)
        (asserts! (is-none (map-get? product-batches {
            batch-identifier: batch-identifier, 
            manufacturer-principal: manufacturer-principal
        })) ERR-PRODUCT-EXISTS)
        
        (ok (map-set product-batches 
            {batch-identifier: batch-identifier, manufacturer-principal: manufacturer-principal}
            {
                producing-facility: tx-sender,
                production-block: current-block-height,
                shelf-life-block: expiration-block-height,
                product-category: product-category,
                batch-hash-code: batch-hash-code,
                supply-chain-notes: supply-chain-notes,
                recall-status: false
            }
        ))
    )
)

(define-public (recall-product-batch 
    (batch-identifier (string-ascii 50)) 
    (manufacturer-principal principal)
)
    (let (
        (batch-record (unwrap! 
            (map-get? product-batches 
                {batch-identifier: batch-identifier, manufacturer-principal: manufacturer-principal}
            ) 
            ERR-PRODUCT-NOT-EXISTS
        ))
    )
        (asserts! (check-string-validity batch-identifier) ERR-INVALID-PARAMETERS)
        (asserts! (check-principal-validity manufacturer-principal) ERR-ZERO-PRINCIPAL)
        (asserts! (is-eq tx-sender (get producing-facility batch-record)) ERR-ACCESS-DENIED)
        (ok (map-set product-batches 
            {batch-identifier: batch-identifier, manufacturer-principal: manufacturer-principal}
            (merge batch-record {recall-status: true})
        ))
    )
)

;; Query functions
(define-read-only (get-batch-details
    (batch-identifier (string-ascii 50))
    (manufacturer-principal principal)
)
    (map-get? product-batches 
        {batch-identifier: batch-identifier, manufacturer-principal: manufacturer-principal}
    )
)

(define-read-only (verify-product-safety
    (batch-identifier (string-ascii 50))
    (manufacturer-principal principal)
)
    (match (map-get? product-batches 
        {batch-identifier: batch-identifier, manufacturer-principal: manufacturer-principal}
    )
        batch-record (let (
            (current-block-height block-height)
            (product-expired (> current-block-height (get shelf-life-block batch-record)))
        )
            (if (get recall-status batch-record)
                ERR-PRODUCT-RECALLED
                (if product-expired
                    ERR-BATCH-EXPIRED
                    (ok true)
                )
            ))
        ERR-PRODUCT-NOT-EXISTS
    )
)

(define-read-only (get-manufacturer-details (manufacturer-principal principal))
    (map-get? certified-manufacturers manufacturer-principal)
)

(define-read-only (get-category-specifications (category-name (string-ascii 50)))
    (map-get? product-categories category-name)
)