///|
let intP = @parserc.pint

///|
let stringP = @parserc.pstring

///|
let charP = @parserc.pchar

///|
typealias Seq[A] = @parserc.Seq[A]

///|
typealias Parser[A] = @parserc.Parser[Char, A]

///|
typealias WholeParser[Repr] = Lazy[Parser[Repr]]

///|
typealias LitParser[Repr] = Lazy[Parser[Repr]]

///|
typealias PlusParser[Repr] = Lazy[Parser[Repr]]

///|
typealias VarParser[Repr] = Lazy[Parser[Repr]]

///|
typealias ExtendedParser[Repr] = Object[(VarParser[Repr], OriginalParser[Repr])]

///|
typealias OriginalParser[Repr] = Object[
  ((LitParser[Repr], PlusParser[Repr]), WholeParser[Repr]),
]

///|
let spaces : @parserc.Parser[Char, Array[Char]] = @parserc.pchar(' ').repeat()

///|
fn originalParser[Repr : AST]() -> OriginalParser[Repr] {
  fn(p) {
    // fn x() {
    //   let wholeP_before = p.force().1.force()
    //   let litP = intP.map(Repr::lit)
    //   let plusP = wholeP_before
    //     .and_then(
    //       spaces
    //       .and_then(charP('+'))
    //       .and_then(spaces)
    //       .and_then(wholeP_before)
    //       .omit_first()
    //       .repeat(),
    //     )
    //     .map(fn {
    //       (x, xs) => xs.fold(init=x, fn(acc, x) { Repr::plus(acc, x) })
    //     })
    //   let wholeP = plusP.or_else(litP)
    //   (plusP, wholeP)
    // }

    Lazy::from_fun(fn() {
      (
        (
          Lazy::from_val(intP.map(Repr::lit)),
          Lazy::from_fun(fn() {
            let wholeP_before = p.force().1.force()
            let plusP = wholeP_before
              .and_then(
                spaces
                .and_then(charP('+'))
                .and_then(spaces)
                .and_then(wholeP_before)
                .omit_first()
                .repeat(),
              )
              .map(fn {
                (x, xs) => xs.fold(init=x, fn(acc, x) { Repr::plus(acc, x) })
              })
            plusP
          }),
        ),
        Lazy::from_fun(fn() {
          let p = p.force().0
          let (litP, plusP) = (p.0.force(), p.1.force())
          let wholeP = plusP.or_else(litP)
          wholeP
        }),
      )
    })
  }
}

// fn extendedParser[Repr : AST + Var]() ->

///|
pub type Object[A] (Lazy[A]) -> Lazy[A]

///|
pub fn Object::use_[A](self : Object[A]) -> Lazy[A] {
  Lazy::fix(self._)
}

///|
pub fn Object::inherit[A, B](
  self : Object[A],
  ab : (Lazy[A]) -> Lazy[B],
  ba : (Lazy[B]) -> Lazy[A]
) -> Object[B] {
  Lazy::compose(ab, Lazy::compose(self._, ba))
}


///|
trait AST {
  lit(Int) -> Self
  plus(Self, Self) -> Self
}

///|
trait Var {
  var(String) -> Self
}

///|
type MyString String

///|
impl Show for MyString with output(self, logger) {
  self._.output(logger)
}

///|
impl AST for MyString with lit(self) {
  self.to_string()
}

///|
impl AST for MyString with plus(lhs, rhs) {
  "\{lhs._} + \{rhs._}"
}

///|
impl Var for MyString with var(self) {
  self
}

///|
fn is_odd(n : Int) -> Bool {
  if n == 0 {
    false
  } else {
    is_even(n - 1)
  }
}

///|
fn is_even(n : Int) -> Bool {
  if n == 0 {
    true
  } else {
    is_odd(n - 1)
  }
}


