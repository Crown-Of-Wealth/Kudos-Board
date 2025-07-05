;; Enhanced Community Kudos Contract
;; Optimized for gas efficiency and better functionality

(define-constant ERR_SAME_SENDER_RECEIVER u100)
(define-constant ERR_TOO_SOON u101)
(define-constant ERR_MESSAGE_TOO_LONG u102)
(define-constant ERR_CATEGORY_TOO_LONG u103)
(define-constant ERR_KUDO_NOT_FOUND u104)
(define-constant ERR_UNAUTHORIZED u105)

;; Maximum limits for validation
(define-constant MAX_MESSAGE_LENGTH u100)
(define-constant MAX_CATEGORY_LENGTH u30)
(define-constant MAX_KUDOS_PER_USER u100)

;; Global state
(define-data-var kudos-count uint u0)
(define-data-var contract-owner principal tx-sender)

;; Core data structures
(define-map kudos
  uint
  {
    sender: principal,
    recipient: principal,
    message: (string-ascii 100),
    category: (string-ascii 30),
    block-sent: uint
  }
)

;; Rate limiting - track last send time per sender-recipient pair
(define-map last-sent
  { sender: principal, recipient: principal }
  uint
)

;; User statistics
(define-map user-stats
  principal
  {
    sent-count: uint,
    received-count: uint,
    last-activity: uint
  }
)

;; Enhanced send-kudo function with validation and batching support
(define-public (send-kudo (to principal) (message (string-ascii 100)) (category (string-ascii 30)))
  (let (
        (sender tx-sender)
        (current-block burn-block-height)
        (last-block (default-to u0 (map-get? last-sent { sender: sender, recipient: to })))
        (new-id (var-get kudos-count))
      )
    ;; Input validation
    (asserts! (not (is-eq sender to)) (err ERR_SAME_SENDER_RECEIVER))
    (asserts! (< (len message) MAX_MESSAGE_LENGTH) (err ERR_MESSAGE_TOO_LONG))
    (asserts! (< (len category) MAX_CATEGORY_LENGTH) (err ERR_CATEGORY_TOO_LONG))
    
    ;; Rate limiting - prevent spam (one kudo per block per sender-recipient pair)
    (asserts! (< last-block current-block) (err ERR_TOO_SOON))
    
    ;; Store kudo
    (map-set kudos new-id {
      sender: sender,
      recipient: to,
      message: message,
      category: category,
      block-sent: current-block
    })
    
    ;; Update rate limiting
    (map-set last-sent { sender: sender, recipient: to } current-block)
    
    ;; Update indexes efficiently
    (update-user-indexes sender to new-id)
    
    ;; Update statistics
    (update-user-stats sender to current-block)
    
    ;; Increment counter
    (var-set kudos-count (+ new-id u1))
    
    (ok { id: new-id, block: current-block })
  )
)

;; Batch send kudos for efficiency
(define-public (send-kudos-batch (recipients (list 10 principal)) (message (string-ascii 100)) (category (string-ascii 30)))
  (let (
        (sender tx-sender)
        (results (map send-single-kudo recipients))
      )
    (ok results)
  )
)

;; Private helper for batch operations
(define-private (send-single-kudo (recipient principal))
  (match (send-kudo recipient "Batch kudo" "batch")
    success success
    error error
  )
)

;; Simplified index updates - just track count instead of full lists
(define-private (update-user-indexes (sender principal) (recipient principal) (kudo-id uint))
  (begin
    ;; We'll just update the stats, no need for complex list management
    true
  )
)

;; Update user statistics
(define-private (update-user-stats (sender principal) (recipient principal) (block-height uint))
  (let (
        (sender-stats (default-to { sent-count: u0, received-count: u0, last-activity: u0 } 
                                 (map-get? user-stats sender)))
        (recipient-stats (default-to { sent-count: u0, received-count: u0, last-activity: u0 } 
                                    (map-get? user-stats recipient)))
      )
    ;; Update sender stats
    (map-set user-stats sender {
      sent-count: (+ (get sent-count sender-stats) u1),
      received-count: (get received-count sender-stats),
      last-activity: block-height
    })
    ;; Update recipient stats
    (map-set user-stats recipient {
      sent-count: (get sent-count recipient-stats),
      received-count: (+ (get received-count recipient-stats) u1),
      last-activity: block-height
    })
  )
)

;; Enhanced read-only functions
(define-read-only (get-kudo (id uint))
  (map-get? kudos id)
)

;; Get kudos sent by user (manual checking approach)
(define-read-only (get-kudos-sent-by-user (user principal))
  (get-user-kudos-sent user (var-get kudos-count))
)

(define-read-only (get-kudos-received-by-user (user principal))
  (get-user-kudos-received user (var-get kudos-count))
)

;; Helper function to manually check kudos sent by user
(define-private (get-user-kudos-sent (user principal) (count uint))
  (let ((results (list)))
    (if (> count u0)
        (append-if-sent-by-user u0 user results count)
        results
    )
  )
)

;; Helper function to manually check kudos received by user
(define-private (get-user-kudos-received (user principal) (count uint))
  (let ((results (list)))
    (if (> count u0)
        (append-if-received-by-user u0 user results count)
        results
    )
  )
)

;; Check if kudo was sent by user and append to results
(define-private (append-if-sent-by-user (kudo-id uint) (user principal) (acc (list 10 uint)) (max-count uint))
  (if (>= kudo-id max-count)
      acc
      (let ((kudo-opt (get-kudo kudo-id)))
        (match kudo-opt
          some-kudo (if (is-eq (get sender some-kudo) user)
                        (let ((new-acc (unwrap-panic (as-max-len? (append acc kudo-id) u10))))
                          (if (< (+ kudo-id u1) max-count)
                              (append-if-sent-by-user (+ kudo-id u1) user new-acc max-count)
                              new-acc
                          )
                        )
                        (if (< (+ kudo-id u1) max-count)
                            (append-if-sent-by-user (+ kudo-id u1) user acc max-count)
                            acc
                        )
                    )
          none (if (< (+ kudo-id u1) max-count)
                   (append-if-sent-by-user (+ kudo-id u1) user acc max-count)
                   acc
               )
        )
      )
  )
)

;; Check if kudo was received by user and append to results
(define-private (append-if-received-by-user (kudo-id uint) (user principal) (acc (list 10 uint)) (max-count uint))
  (if (>= kudo-id max-count)
      acc
      (let ((kudo-opt (get-kudo kudo-id)))
        (match kudo-opt
          some-kudo (if (is-eq (get recipient some-kudo) user)
                        (let ((new-acc (unwrap-panic (as-max-len? (append acc kudo-id) u10))))
                          (if (< (+ kudo-id u1) max-count)
                              (append-if-received-by-user (+ kudo-id u1) user new-acc max-count)
                              new-acc
                          )
                        )
                        (if (< (+ kudo-id u1) max-count)
                            (append-if-received-by-user (+ kudo-id u1) user acc max-count)
                            acc
                        )
                    )
          none (if (< (+ kudo-id u1) max-count)
                   (append-if-received-by-user (+ kudo-id u1) user acc max-count)
                   acc
               )
        )
      )
  )
)

;; Create a simple range from 0 to count-1 (max 10 items for gas efficiency)
(define-private (create-range (count uint))
  (if (<= count u1)
      (if (is-eq count u0) 
          (list) 
          (list u0))
      (if (is-eq count u2)
          (list u0 u1)
          (if (is-eq count u3)
              (list u0 u1 u2)
              (if (is-eq count u4)
                  (list u0 u1 u2 u3)
                  (if (is-eq count u5)
                      (list u0 u1 u2 u3 u4)
                      (if (is-eq count u6)
                          (list u0 u1 u2 u3 u4 u5)
                          (if (is-eq count u7)
                              (list u0 u1 u2 u3 u4 u5 u6)
                              (if (is-eq count u8)
                                  (list u0 u1 u2 u3 u4 u5 u6 u7)
                                  (if (is-eq count u9)
                                      (list u0 u1 u2 u3 u4 u5 u6 u7 u8)
                                      ;; For 10 or more, return first 10
                                      (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
                                  )
                              )
                          )
                      )
                  )
              )
          )
      )
  )
)

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats user)
)

(define-read-only (get-kudo-count)
  (var-get kudos-count)
)

;; Get specific kudos by ID range (simpler approach)
(define-read-only (get-kudos-by-range (start-id uint) (end-id uint))
  (let (
        (total-count (var-get kudos-count))
        (safe-start (if (< start-id total-count) start-id total-count))
        (safe-end (if (< end-id total-count) end-id total-count))
      )
    ;; Return up to 10 recent kudos manually
    (if (> safe-end safe-start)
        (list 
          (get-kudo safe-start)
          (get-kudo (+ safe-start u1))
          (get-kudo (+ safe-start u2))
          (get-kudo (+ safe-start u3))
          (get-kudo (+ safe-start u4))
          (get-kudo (+ safe-start u5))
          (get-kudo (+ safe-start u6))
          (get-kudo (+ safe-start u7))
          (get-kudo (+ safe-start u8))
          (get-kudo (+ safe-start u9))
        )
        (list)
    )
  )
)

;; Utility function to check if user can send kudo
(define-read-only (can-send-kudo (sender principal) (recipient principal))
  (let (
        (current-block burn-block-height)
        (last-block (default-to u0 (map-get? last-sent { sender: sender, recipient: recipient })))
      )
    (and 
      (not (is-eq sender recipient))
      (< last-block current-block)
    )
  )
)

;; Admin functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)