(module
  ;; iterative fibonacci
  (func $fib (export "fib") (param $n i32) (result i32)
    (local $a i32) (local $b i32) (local $t i32)
    (local.set $b (i32.const 1))
    (block $done
      (loop $next
        (br_if $done (i32.eqz (local.get $n)))
        (local.set $t (i32.add (local.get $a) (local.get $b)))
        (local.set $a (local.get $b))
        (local.set $b (local.get $t))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (br $next)))
    (local.get $a))

  ;; returns 1 if n is even
  (func (export "is_even") (param $n i32) (result i32)
    (i32.eqz (i32.and (local.get $n) (i32.const 1))))
)
