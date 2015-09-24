import os

type
  Observer[A] = object
    onSubscribe: proc(s: Subscriber[A])
  Subscriber[A] = object
    onNext: proc(a: A)
    onComplete: proc()
    onError: proc()

proc noop() = discard
proc noop(a: auto) = discard

proc println[A](a: A) = echo(a)

proc create[A](p: proc(s: Subscriber[A])): Observer[A] =
  result.onSubscribe = p

proc observer[A](xs: seq[A]): Observer[A] =
  create(proc(s: Subscriber[A]) =
    for x in xs:
      s.onNext(x)
    s.onComplete()
  )

proc single[A](a: A): Observer[A] = observer(@[a])

proc subscriber[A](onNext: proc(a: A), onComplete: proc() = noop, onError: proc() = noop): Subscriber[A] =
  result.onNext = onNext
  result.onComplete = onComplete
  result.onError = onError

proc subscribe[A](o: Observer[A], s: Subscriber[A]) =
  o.onSubscribe(s)

proc map[A, B](o: Observer[A], f: proc(a: A): B): Observer[B] =
  create(proc(s: Subscriber[B]) =
    o.subscribe(subscriber(
      onNext = proc(a: A) = s.onNext(f(a)),
      onComplete = s.onComplete,
      onError = s.onError
    ))
  )

proc filter[A](o: Observer[A], f: proc(a: A): bool): Observer[A] =
  create(proc(s: Subscriber[A]) =
    o.subscribe(subscriber(
      onNext = proc(a: A) =
        if f(a): s.onNext(a),
      onComplete = s.onComplete,
      onError = s.onError
    ))
  )

proc delay[A](o: Observer[A], millis: int): Observer[A] =
  create(proc(s: Subscriber[A]) =
    o.subscribe(subscriber(
      onNext = proc(a: A) =
        s.onNext(a)
        sleep(millis),
      onComplete = s.onComplete,
      onError = s.onError
    ))
  )

proc concat[A](o1, o2: Observer[A]): Observer[A] =
  create(proc(s: Subscriber[A]) =
    o1.subscribe(subscriber(
      onNext = s.onNext,
      onComplete = proc() =
        o2.subscribe(s),
      onError = s.onError
    ))
  )


when isMainModule:
  import future
  observer(@[1, 2, 3, 4, 5])
    .map((x: int) => x * x)
    .filter((x: int) => x > 3)
    .delay(500)
    .concat(single(6))
    .subscribe(subscriber[int](println))