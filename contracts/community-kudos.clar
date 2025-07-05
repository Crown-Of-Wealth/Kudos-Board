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

;; Update user statistics - defined before use
(define-private (update-user-stats (sender principal) (recipient principal) (current-block uint))
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
      last-activity: current-block
    })
    ;; Update recipient stats
    (map-set user-stats recipient {
      sent-count: (get sent-count recipient-stats),
      received-count: (+ (get received-count recipient-stats) u1),
      last-activity: current-block
    })
  )
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
    
    ;; Update user statistics
    (update-user-stats sender to current-block)
    
    ;; Increment counter
    (var-set kudos-count (+ new-id u1))
    
    (ok { id: new-id, block: current-block })
  )
)

;; Private helper for batch operations
(define-private (send-single-kudo-batch (recipient principal))
  (send-kudo recipient "Batch kudo" "batch")
)

;; Batch send kudos for efficiency
(define-public (send-kudos-batch (recipients (list 10 principal)) (message (string-ascii 100)) (category (string-ascii 30)))
  (let (
        (sender tx-sender)
        (results (map send-single-kudo-batch recipients))
      )
    (ok results)
  )
)

;; Enhanced read-only functions
(define-read-only (get-kudo (id uint))
  (map-get? kudos id)
)

;; Get kudos sent by user - simplified approach without circular dependencies
(define-read-only (get-kudos-sent-by-user (user principal))
  (let (
        (total-count (var-get kudos-count))
        (max-check (if (> total-count u10) u10 total-count))
      )
    (get-sent-kudos-list user u0 max-check)
  )
)

;; Get kudos received by user - simplified approach without circular dependencies
(define-read-only (get-kudos-received-by-user (user principal))
  (let (
        (total-count (var-get kudos-count))
        (max-check (if (> total-count u10) u10 total-count))
      )
    (get-received-kudos-list user u0 max-check)
  )
)

;; Helper function to get sent kudos list (non-recursive approach)
(define-private (get-sent-kudos-list (user principal) (start-id uint) (max-id uint))
  (let (
        (kudo-0 (get-kudo-if-sent-by-user user start-id))
        (kudo-1 (get-kudo-if-sent-by-user user (+ start-id u1)))
        (kudo-2 (get-kudo-if-sent-by-user user (+ start-id u2)))
        (kudo-3 (get-kudo-if-sent-by-user user (+ start-id u3)))
        (kudo-4 (get-kudo-if-sent-by-user user (+ start-id u4)))
        (kudo-5 (get-kudo-if-sent-by-user user (+ start-id u5)))
        (kudo-6 (get-kudo-if-sent-by-user user (+ start-id u6)))
        (kudo-7 (get-kudo-if-sent-by-user user (+ start-id u7)))
        (kudo-8 (get-kudo-if-sent-by-user user (+ start-id u8)))
        (kudo-9 (get-kudo-if-sent-by-user user (+ start-id u9)))
      )
    (build-kudo-list (list kudo-0 kudo-1 kudo-2 kudo-3 kudo-4 kudo-5 kudo-6 kudo-7 kudo-8 kudo-9))
  )
)

;; Helper function to get received kudos list (non-recursive approach)
(define-private (get-received-kudos-list (user principal) (start-id uint) (max-id uint))
  (let (
        (kudo-0 (get-kudo-if-received-by-user user start-id))
        (kudo-1 (get-kudo-if-received-by-user user (+ start-id u1)))
        (kudo-2 (get-kudo-if-received-by-user user (+ start-id u2)))
        (kudo-3 (get-kudo-if-received-by-user user (+ start-id u3)))
        (kudo-4 (get-kudo-if-received-by-user user (+ start-id u4)))
        (kudo-5 (get-kudo-if-received-by-user user (+ start-id u5)))
        (kudo-6 (get-kudo-if-received-by-user user (+ start-id u6)))
        (kudo-7 (get-kudo-if-received-by-user user (+ start-id u7)))
        (kudo-8 (get-kudo-if-received-by-user user (+ start-id u8)))
        (kudo-9 (get-kudo-if-received-by-user user (+ start-id u9)))
      )
    (build-kudo-list (list kudo-0 kudo-1 kudo-2 kudo-3 kudo-4 kudo-5 kudo-6 kudo-7 kudo-8 kudo-9))
  )
)

;; Helper function to build list of kudo IDs from optional values
(define-private (build-kudo-list (opt-list (list 10 (optional uint))))
  (let (
        (result (list))
      )
    (fold add-if-some opt-list result)
  )
)

;; Helper function to add kudo ID to result if it has a value
(define-private (add-if-some (opt-kudo (optional uint)) (acc (list 10 uint)))
  (match opt-kudo
    some-kudo (unwrap-panic (as-max-len? (append acc some-kudo) u10))
    acc
  )
)

;; Helper to get kudo ID if sent by user
(define-private (get-kudo-if-sent-by-user (user principal) (kudo-id uint))
  (let ((kudo-opt (get-kudo kudo-id)))
    (match kudo-opt
      some-kudo (if (is-eq (get sender some-kudo) user)
                    (some kudo-id)
                    none)
      none
    )
  )
)

;; Helper to get kudo ID if received by user
(define-private (get-kudo-if-received-by-user (user principal) (kudo-id uint))
  (let ((kudo-opt (get-kudo kudo-id)))
    (match kudo-opt
      some-kudo (if (is-eq (get recipient some-kudo) user)
                    (some kudo-id)
                    none)
      none
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