pub enum LazyRepr[A] {
  Value(A)
  Thunk(() -> A)
}

pub type Lazy[A] Ref[LazyRepr[A]]


fn Lazy::lazy_map[A,B](self : Lazy[A], f : (A) -> B) -> Lazy[B] {
  match self._.val {
    Value(val) => Lazy::from_val(f(val))
    Thunk(fun) => Lazy::from_fun(fn () { f(fun()) } )
  }
}

fn Lazy::lazy_join[A](self : Lazy[Lazy[A]]) -> Lazy[A] {
  match self._.val {
    Value(val) => val 
    Thunk(fun) => fun() 
  }
}


fn Lazy::force[A](self : Lazy[A]) -> A {
  match self._.val {
    Value(v) => v
    Thunk(f) => {  
      let v = f() 
      self._.val = Value(v)
      v
     }
  }
}

fn Lazy::from_fun[A](f : () -> A)  -> Lazy[A] {
  Ref::new(Thunk(f))
}
fn Lazy::from_val[A](v : A) -> Lazy[A] {
  Ref::new(Value(v))
}

fn Lazy::fix[A](f : (Lazy[A]) -> Lazy[A]) -> Lazy[A] {
  let mut x = None 
  fn fun() -> A {
    f(x.unwrap()).force()
  }
  x = Some(Lazy::from_fun(fun))
  x.unwrap()
}

fn Lazy::compose[A,B,C](f : (Lazy[B]) -> Lazy[C], g : (Lazy[A]) -> Lazy[B]) -> (Lazy[A]) -> Lazy[C] {
  @fun.compose(f,g)
}

fn Lazy::force_pair[A,B](self : Lazy[(Lazy[A],Lazy[B])]) -> (A,B) {
  let (a,b) = self.force()
  (a.force(),b.force())
}

