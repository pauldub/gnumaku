(define-module (demo player)
  #:use-module (oop goops)
  #:use-module (gnumaku generics)
  #:use-module (gnumaku core)
  #:use-module (gnumaku coroutine)
  #:use-module (gnumaku events)
  #:use-module (gnumaku scene-graph)
  #:use-module (gnumaku assets)
  #:use-module (demo actor)
  #:use-module (demo level)
  #:export (<player> make-player sprite speed movement shooting score graze-count lives
                     power invincible bounds shot set-movement invincible-mode add-points
                     graze-hitbox))

(define (make-movement-hash)
  (let ((hash (make-hash-table)))
    (hash-set! hash 'up #f)
    (hash-set! hash 'down #f)
    (hash-set! hash 'left #f)
    (hash-set! hash 'right #f)
    hash))

(define (make-bounds)
  (make-rect -24 -24 48 48))

(define (make-hitbox)
  (make-rect -4 -4 8 8))

(define (make-graze-hitbox)
  (make-rect -8 -8 16 16))

(define (make-player-sprite)
  (make-sprite (sprite-sheet-tile (load-asset "player.png" 48 48 0 0) 0)))

(define-class <player> (<actor>)
  (sprite #:accessor sprite #:init-keyword #:sprite #:init-value #f)
  (speed #:accessor speed #:init-keyword #:speed #:init-value 5)
  (movement #:accessor movement #:init-keyword #:movement #:init-thunk make-movement-hash)
  (shooting #:accessor shooting #:init-keyword #:shooting #:init-value #f)
  (score #:accessor score #:init-keyword #:score #:init-value 0)
  (graze-count #:accessor graze-count #:init-keyword #:graze-count #:init-value 0)
  (lives #:accessor lives #:init-keyword #:lives #:init-value 3)
  (power #:accessor power #:init-keyword #:power #:init-value 10)
  (invincible #:accessor invincible #:init-keyword #:invincible #:init-value #f)
  (bounds #:accessor bounds #:init-thunk make-bounds)
  (graze-hitbox #:accessor graze-hitbox #:init-thunk make-graze-hitbox)
  (shot #:accessor shot #:init-keyword #:shot #:init-value #f))

(define (make-player)
  (let ((player (make <player> #:sprite (make-player-sprite)
                      #:hitbox (make-hitbox))))
    (center-sprite-image! (sprite player))
    player))

(define-method (set-shooting (player <player>) new-shooting)
  "Sets player shooting flag. Calls shot procedure when flag is set to #t."
  (slot-set! player 'shooting new-shooting)
  ;; SHOOT!
  (when (and new-shooting (procedure? (shot player)))
    ((shot player) player)))

;; Override setter for shooting slot
(define shooting (make-procedure-with-setter shooting set-shooting))

(define-method (set-lives (player <player>) new-lives)
  (slot-set! player 'lives new-lives)
  (dispatch player 'lives-changed new-lives))

(define lives (make-procedure-with-setter lives set-lives))

(define-method (set-score (player <player>) new-score)
  (slot-set! player 'score new-score)
  (dispatch player 'score-changed new-score))

(define score (make-procedure-with-setter score set-score))

(define-method (%draw (player <player>))
  (draw-sprite (sprite player)))

(define-method (update (player <player>))
  (next-method)
  (when (moving? player)
    (let ((direction (direction player)))
      (set! (x player) (+ (x player) (dx player direction)))
      (set! (y player) (+ (y player) (dy player direction)))
      (restrict-bounds player))))

(define-method (dx (player <player>) direction)
  (* (speed player) (cos direction)))

(define-method (dy (player <player>) direction)
  (* (speed player) (sin direction)))

(define-method (set-movement (player <player>) direction flag)
  (hash-set! (movement player) direction flag))

(define-method (direction? (player <player>) direction)
  (hash-ref (movement player) direction))

(define-method (moving? (player <player>))
  (or
   (direction? player 'up)
   (direction? player 'down)
   (direction? player 'left)
   (direction? player 'right)))

(define-method (direction (player <player>))
  (let ((x 0)
	(y 0))
    (when (direction? player 'left)
      (set! x (- x 1)))
    (when (direction? player 'right)
      (set! x (+ x 1)))
    (when (direction? player 'up)
      (set! y (- y 1)))
    (when (direction? player 'down)
      (set! y (+ y 1)))
    (atan y x)))

(define-method (restrict-bounds (player <player>))
  (let ((bounds (rect-move (bounds player) (x player) (y player)))
        (level (level player)))
    (let ((x (x player))
          (y (y player))
          (left (rect-x bounds))
          (top (rect-y bounds))
          (right (+ (rect-x bounds) (rect-width bounds)))
          (bottom (+ (rect-y bounds) (rect-height bounds)))
          (width (width level))
          (height (height level)))
      ;; Confine x and y to within the boundaries so the player doesn't scroll off screen
      (when (< left 0)
        (set! x (- x left)))
      (when (< top 0)
        (set! y (- y top)))
      (when (> right width)
        (set! x (- x (- right width))))
      (when (> bottom height)
        (set! y (- y (- bottom height))))
      ;; Update position
      (set-position player x y))))

(define-method (add-points (player <player>) points)
  (set! (score player) (+ (score player) points)))

(define-method (invincible-mode (player <player>) duration)
  (coroutine (set! (invincible player) #t)
             (wait player duration)
             (set! (invincible player) #f)))
