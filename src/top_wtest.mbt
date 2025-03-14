///|
// test {
//   let parser : OriginalParser[MyString] = originalParser()
//   let parser = parser.use_().force_tuple()
//   let res = parser.1.parse(Seq::from_string("1 + 2 + 3"))
//   inspect!(
//     res,
//     content=
//       #|Some(("1 + 2 + 3", ))
//     ,
//   )
// }

// ///|
// test {
//   let x = Lazy::fix(fn(_) { Lazy::from_val(2) }).force()
//   inspect!(x, content="2")
// }

///|
// test {
//   let x : Object[(Lazy[Int], Lazy[Int])] = fn(self) {
//     Lazy::from_fun(fn() {
//       (
//         Lazy::from_fun(fn() { 2 }),
//         Lazy::from_fun(fn() {
//           let self = self.force()
//           self.0.force() + self.0.force()
//         }),
//       )
//     })
//   }
//   let x_val = x.use_().force_pair()
//   inspect!(x_val, content="(2, 4)")
//   let x = x.inherit(
//     fn(self) {
//       Lazy::from_fun(fn() {
//         (
//           (
//             Lazy::from_fun(fn() {
//               let l = self.force().0.force()
//               l + 1
//             }),
//             Lazy::from_fun(fn() {
//               let r = self.force().1.force()
//               r + 2
//             }),
//           ),
//           Lazy::from_fun(fn() {
//             let r = self.force().1.force()
//             r + 1
//           }),
//         )
//       })
//     },
//     fn(self) {
//       Lazy::from_fun(fn() {
//         let self = self.force()
//         self.0
//       })
//     },
//   )
//   let x_val = x.use_().force_tuple()
//   inspect!(x_val, content="((3, 8), 7)")
// }

///|
/// 
/// 
test {
  let x : Object[(Lazy[(Int) -> Bool], Lazy[(Int) -> Bool])] = fn(self) {
    Lazy::from_fun(fn() {
      (
        Lazy::from_fun(fn() {
          fn(n) {
            self.force().1.lazy_map(fn(is_even) {
              fn(n) {
                if n == 0 {
                  true
                } else {
                  is_even(n - 1) 
                }
              }
            }).force()(n)     
          }
        }),
                Lazy::from_fun(fn() {
          fn(n) {
            self.force().1.lazy_map(fn(is_odd) {
              fn(n) {
                if n == 0 {
                  true
                } else {
                  is_odd(n - 1) 
                }
              }
            }).force()(n)     
          }
        }),
      )
    })
  }
  let (is_odd,is_even) = x.use_().force_pair()
  inspect!(is_odd(5), content="true")
  inspect!(is_even(5), content="true")
}
