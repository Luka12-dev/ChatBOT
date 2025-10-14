// native/rust_stub.rs
#[no_mangle]
pub extern "C" fn run_inference(ptr: *const u8, len: usize) -> *mut u8 {
    // Prompt string
    let slice = unsafe { std::slice::from_raw_parts(ptr, len) };
    let prompt = String::from_utf8_lossy(slice);
    let resp = format!("Rust native stub reply for: {}", prompt);
    let mut v = resp.into_bytes();
    v.push(0);
    let p = v.as_mut_ptr();
    std::mem::forget(v);
    p
}

#[no_mangle]
pub extern "C" fn free_c_char_ptr(ptr: *mut u8) {
    if ptr.is_null() { return; }
    unsafe {
        // find length
        let mut len = 0usize;
        while *ptr.add(len) != 0 { len += 1; }
        let _ = Vec::from_raw_parts(ptr, len, len+1);
    }
}