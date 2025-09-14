;; Title: Advanced Smart Contract Implementation
;; Description: Comprehensive Clarity smart contract with advanced features
;; Version: 1.0.0

;; =============================================================================
;; CONSTANTS AND ERROR CODES
;; =============================================================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1001))
(define-constant ERR_INVALID_AMOUNT (err u1002))
(define-constant ERR_INSUFFICIENT_BALANCE (err u1003))
(define-constant ERR_ALREADY_EXISTS (err u1004))
(define-constant ERR_NOT_FOUND (err u1005))
(define-constant ERR_INVALID_RECIPIENT (err u1006))
(define-constant ERR_CONTRACT_DISABLED (err u1007))
(define-constant ERR_INVALID_PARAMETERS (err u1008))
(define-constant ERR_EXPIRED (err u1009))
(define-constant ERR_PENDING (err u1010))

;; =============================================================================
;; DATA VARIABLES
;; =============================================================================

(define-data-var contract-enabled bool true)
(define-data-var total-supply uint u0)
(define-data-var admin principal CONTRACT_OWNER)
(define-data-var fee-percentage uint u250) ;; 2.5%
(define-data-var min-amount uint u1000000) ;; 1 STX minimum
(define-data-var max-amount uint u1000000000000) ;; 1M STX maximum

;; =============================================================================
;; DATA MAPS
;; =============================================================================

(define-map Balances principal uint)
(define-map Allowances {spender: principal, owner: principal} uint)
(define-map UserProfiles
  principal
  {
    created-at: uint,
    total-transactions: uint,
    reputation-score: uint,
    verified: bool
  }
)

(define-map Transactions
  uint
  {
    id: uint,
    from: principal,
    to: principal,
    amount: uint,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

;; =============================================================================
;; PRIVATE FUNCTIONS
;; =============================================================================

(define-private (is-contract-enabled)
  (var-get contract-enabled)
)

(define-private (is-authorized (user principal))
  (or (is-eq user CONTRACT_OWNER)
      (is-eq user (var-get admin)))
)

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get fee-percentage)) u10000)
)

(define-private (update-user-stats (user principal))
  (let ((profile (default-to
                  {created-at: block-height, total-transactions: u0, reputation-score: u100, verified: false}
                  (map-get? UserProfiles user))))
    (map-set UserProfiles user
      (merge profile {
        total-transactions: (+ (get total-transactions profile) u1),
        reputation-score: (min u1000 (+ (get reputation-score profile) u1))
      }))
  )
)

(define-private (validate-amount (amount uint))
  (and (>= amount (var-get min-amount))
       (<= amount (var-get max-amount))
       (> amount u0))
)

(define-private (get-balance-or-default (account principal))
  (default-to u0 (map-get? Balances account))
)

;; =============================================================================
;; READ-ONLY FUNCTIONS
;; =============================================================================

(define-read-only (get-balance (account principal))
  (ok (get-balance-or-default account))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-contract-info)
  {
    enabled: (var-get contract-enabled),
    admin: (var-get admin),
    fee-percentage: (var-get fee-percentage),
    min-amount: (var-get min-amount),
    max-amount: (var-get max-amount),
    total-supply: (var-get total-supply)
  }
)

(define-read-only (get-user-profile (user principal))
  (map-get? UserProfiles user)
)

(define-read-only (get-allowance (owner principal) (spender principal))
  (default-to u0 (map-get? Allowances {spender: spender, owner: owner}))
)

(define-read-only (is-valid-amount (amount uint))
  (validate-amount amount)
)

;; =============================================================================
;; PUBLIC FUNCTIONS
;; =============================================================================

(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender)
        (sender-balance (get-balance-or-default sender)))
    (asserts! (is-contract-enabled) ERR_CONTRACT_DISABLED)
    (asserts! (validate-amount amount) ERR_INVALID_AMOUNT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (not (is-eq sender recipient)) ERR_INVALID_RECIPIENT)
    
    ;; Update balances
    (map-set Balances sender (- sender-balance amount))
    (map-set Balances recipient (+ (get-balance-or-default recipient) amount))
    
    ;; Update user statistics
    (update-user-stats sender)
    (update-user-stats recipient)
    
    ;; Emit transfer event through print
    (print {
      event: "transfer",
      from: sender,
      to: recipient,
      amount: amount,
      block-height: block-height
    })
    
    (ok amount)
  )
)

(define-public (approve (spender principal) (amount uint))
  (let ((owner tx-sender))
    (asserts! (is-contract-enabled) ERR_CONTRACT_DISABLED)
    (asserts! (not (is-eq owner spender)) ERR_INVALID_RECIPIENT)
    
    (map-set Allowances {spender: spender, owner: owner} amount)
    
    (print {
      event: "approval",
      owner: owner,
      spender: spender,
      amount: amount
    })
    
    (ok amount)
  )
)

(define-public (transfer-from (owner principal) (recipient principal) (amount uint))
  (let ((spender tx-sender)
        (owner-balance (get-balance-or-default owner))
        (allowance (get-allowance owner spender)))
    (asserts! (is-contract-enabled) ERR_CONTRACT_DISABLED)
    (asserts! (validate-amount amount) ERR_INVALID_AMOUNT)
    (asserts! (>= owner-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= allowance amount) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq owner recipient)) ERR_INVALID_RECIPIENT)
    
    ;; Update balances and allowance
    (map-set Balances owner (- owner-balance amount))
    (map-set Balances recipient (+ (get-balance-or-default recipient) amount))
    (map-set Allowances {spender: spender, owner: owner} (- allowance amount))
    
    ;; Update statistics
    (update-user-stats owner)
    (update-user-stats recipient)
    
    (print {
      event: "transfer-from",
      owner: owner,
      spender: spender,
      recipient: recipient,
      amount: amount
    })
    
    (ok amount)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-contract-enabled) ERR_CONTRACT_DISABLED)
    (asserts! (validate-amount amount) ERR_INVALID_AMOUNT)
    
    ;; Update recipient balance and total supply
    (map-set Balances recipient (+ (get-balance-or-default recipient) amount))
    (var-set total-supply (+ (var-get total-supply) amount))
    
    (update-user-stats recipient)
    
    (print {
      event: "mint",
      recipient: recipient,
      amount: amount,
      total-supply: (var-get total-supply)
    })
    
    (ok amount)
  )
)

;; =============================================================================
;; ADMIN FUNCTIONS
;; =============================================================================

(define-public (set-contract-enabled (enabled bool))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (var-set contract-enabled enabled)
    (print {event: "contract-status-changed", enabled: enabled})
    (ok enabled)
  )
)

(define-public (update-fee (new-fee uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_PARAMETERS) ;; Max 10%
    (var-set fee-percentage new-fee)
    (print {event: "fee-updated", new-fee: new-fee})
    (ok new-fee)
  )
)

(define-public (set-limits (min-amt uint) (max-amt uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
    (asserts! (< min-amt max-amt) ERR_INVALID_PARAMETERS)
    (var-set min-amount min-amt)
    (var-set max-amount max-amt)
    (print {event: "limits-updated", min-amount: min-amt, max-amount: max-amt})
    (ok {min: min-amt, max: max-amt})
  )
)
