# Rust Testing Reference

**Load this reference when:** writing Rust tests, understanding testing patterns.

## Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic() {
        assert_eq!(add(2, 2), 4);
    }

    #[test]
    fn test_with_result() {
        let result = parse("valid");
        assert!(result.is_ok());
    }
}
```

## Parameterized Tests (rstest)

```rust
use rstest::rstest;

#[rstest]
#[case("a", 1)]
#[case("bb", 2)]
#[case("ccc", 3)]
fn test_length(#[case] input: &str, #[case] expected: usize) {
    assert_eq!(input.len(), expected);
}

// With error cases
#[rstest]
#[case("valid@email.com", true)]
#[case("", false)]
#[case("invalid", false)]
fn test_email(#[case] input: &str, #[case] expected: bool) {
    assert_eq!(is_valid_email(input), expected);
}
```

## Mocking (mockall)

```rust
#[automock]
trait Store {
    fn get(&self, key: &str) -> Option<String>;
    fn set(&mut self, key: &str, value: String);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_with_mock() {
        let mut mock = MockStore::new();
        mock.expect_get()
            .with(mockall::predicate::eq("key"))
            .returning(|_| Some("value".to_string()));
        
        assert_eq!(mock.get("key"), Some("value".to_string()));
    }
}
```

## Async Tests

```rust
#[tokio::test]
async fn test_async_fn() {
    let result = async_operation().await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_with_timeout() {
    tokio::time::timeout(Duration::from_secs(5), long_operation())
        .await
        .expect("timed out");
}
```

## Property-Based Testing (proptest)

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_roundtrip(v in any::<Vec<i32>>()) {
        let encoded = encode(&v);
        let decoded = decode(&encoded).unwrap();
        prop_assert_eq!(v, decoded);
    }
}

// With custom strategies
proptest! {
    #[test]
    fn test_sort(random_vec in prop::collection::vec(
        any::<i32>(),
        0..1000
    )) {
        let sorted = sort(random_vec.clone());
        let mut expected = random_vec;
        expected.sort();
        prop_assert_eq!(sorted, expected);
    }
}
```

## Benchmarks (Criterion)

```rust
use criterion::{criterion_group, criterion_main, Criterion};

pub fn sort_benchmark(c: &mut Criterion) {
    c.bench_function("sort 1000", |b| {
        b.iter(|| sort_vec(1000))
    });
}

criterion_group!(benches, sort_benchmark);
criterion_main!(benches);

// Custom measurement
pub fn throughput_benchmark(c: &mut Criterion) {
    let data = (0..1000).collect::<Vec<_>>();
    c.bench_function("process 1000", |b| {
        b.iter(|| process_all(&data))
    });
}
```

## Doc Tests

```rust
/// Adds one to a number.
///
/// # Examples
///
/// ```
/// # use my_crate::add_one;
/// assert_eq!(add_one(2), 3);
/// ```
pub fn add_one(x: i32) -> i32 {
    x + 1
}
```

## Coverage

```bash
# Use cargo-tarpaulin
cargo install cargo-tarpaulin
cargo tarpaulin --out Html

# Or llvm-cov
rustup component add llvm-tools-preview
cargo install cargo-llvm-cov
cargo llvm-cov --html
```