(define-constant ERR_SAME_SENDER_RECEIVER 100)
(define-constant ERR_TOO_SOON 101)
(define-constant ERR_MESSAGE_TOO_LONG 102)
(define-constant ERR_CATEGORY_TOO_LONG 103)

(define-data-var kudos-count uint u0)
(define-map kudos
  uint
  {
    sender: principal,
    recipient: principal,
    message: (buff 100),
    category: (buff 30),
    block-sent: uint
  }
)

(define-map last-sent
  { sender: principal, recipient: principal }
  uint
)

(define-map kudos-index-by-user
  principal
  (list 100 uint)
)

(define-public (send-kudo (to principal) (message (buff 100)) (category (buff 30)))
  (let (
        (sender tx-sender)
        (current-block-height (block-height))
        (last-block (default-to u0 (map-get? last-sent { sender: sender, recipient: to })))
      )
    ;; Prevent spamming - only one kudo per sender->recipient per block
    (if (is-eq sender to)
        (err ERR_SAME_SENDER_RECEIVER)
        (if (>= last-block current-block-height)
            (err ERR_TOO_SOON)
            (let (
                  (new-id (var-get kudos-count))
                )
              (begin
                ;; Save the kudo entry
                (map-set kudos new-id {
                  sender: sender,
                  recipient: to,
                  message: message,
                  category: category,
                  block-sent: current-block-height
                })
                ;; Update index
                (map-set last-sent { sender: sender, recipient: to } current-block-height)
                (map-set kudos-index-by-user to (cons new-id (default-to (list) (map-get? kudos-index-by-user to))))
                ;; Increment global kudo count
                (var-set kudos-count (+ new-id u1))
                (ok { id: new-id })
              )
            )
        )
    )
  )
)

(define-read-only (get-kudo (id uint))
  (map-get? kudos id)
)

(define-read-only (get-kudos-by-user (user principal))
  (default-to (list) (map-get? kudos-index-by-user user))
)

(define-read-only (get-kudo-count)
  (var-get kudos-count)
)