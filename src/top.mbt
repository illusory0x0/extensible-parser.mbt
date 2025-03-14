///|
let intP = @parserc.pint

///|
let letterP : Parser[Char] = @parserc.pvalue(fn(ch : Char) {
  if ch.is_ascii_alphabetic() {
    Some(ch)
  } else {
    None
  }
})

///|
let stringP : Parser[String] = letterP
  .and_then(letterP.repeat())
  .map(fn {
    (x, xs) => {
      let buf = StringBuilder::new(size_hint=2 * (xs.length() + 1))
      buf.write_char(x)
      for x in xs {
        buf.write_char(x)
      }
      buf.to_string()
    }
  })

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
typealias ExtendedParser[Repr] = (VarParser[Repr], OriginalParser[Repr])

///|
typealias OriginalParser[Repr] = (
  (LitParser[Repr], PlusParser[Repr]),
  WholeParser[Repr],
)

///|
let spaces : @parserc.Parser[Char, Array[Char]] = @parserc.pchar(' ').repeat()

///|
pub fn between[A, B, C](
  content : Parser[A],
  left~ : Parser[B],
  right~ : Parser[C]
) -> Parser[A] {
  left.and_then(content).omit_first().and_then(right).omit_second()
}

///|
fn originalParser[Repr : AST]() -> Object[OriginalParser[Repr]] {
  fn(self) {
    Lazy::from_fun(fn() {
      let litP = Lazy::from_val(intP.map(Repr::lit))
      let plusP = Lazy::from_fun(fn() {
        Parser::new(fn(seq) { 
          let plusP : Lazy[Parser[Repr]] = self.force().1.lazy_map(fn(wholeP) {
            between(
              wholeP
              .and_then(spaces)
              .omit_second()
              .and_then(charP('+'))
              .omit_second()
              .and_then(spaces)
              .omit_second()
              .and_then(wholeP),
              left=charP('('),
              right=charP(')'),
            ).map(fn { (lhs, rhs) => Repr::plus(lhs, rhs) })
          })
          plusP.force().parse(seq)
        })
      })
      let wholeP = Lazy::from_fun(fn() {
        Parser::new(fn(seq) { 
          let self = self.force().0
          let wholeP : Lazy[Lazy[Parser[Repr]]] = self.0.lazy_map(fn(litP) {
            self.1.lazy_map(fn(plusP) {
              let wholeP = plusP.or_else(litP)
              wholeP
            })
          })
          wholeP.lazy_join().force().parse(seq)
        })
      })
      ((litP, plusP), wholeP)
    })
  }
}

///|
fn extendedParser[Repr : AST + Var]() -> Object[ExtendedParser[Repr]] {
  fn extend(self : Lazy[OriginalParser[Repr]]) -> Lazy[ExtendedParser[Repr]] {
    self.lazy_map(fn(original) {
      let ((litP, plusP), wholeP) = original
      let varP = stringP.map(Repr::var)
      (
        Lazy::from_val(varP),
        ((litP, plusP), Lazy::from_fun(fn() { wholeP.force().or_else(varP) })),
      )
    })
  }

  fn from_extend(
    self : Lazy[ExtendedParser[Repr]]
  ) -> Lazy[OriginalParser[Repr]] {
    self.lazy_map(fn(extended) { extended.1 })
  }

  let originalParser : Object[OriginalParser[Repr]] = originalParser()
  originalParser.inherit(extend, from_extend)
}

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
pub trait AST {
  lit(Int) -> Self
  plus(Self, Self) -> Self
}

///|
pub trait Var {
  var(String) -> Self
}

///|
pub type MyString String

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
