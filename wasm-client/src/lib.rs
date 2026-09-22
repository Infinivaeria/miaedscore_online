const REFERENCE_NEW_MOON_UNIX_SECONDS: f64 = 947_116_800.0;
const LUNAR_CYCLE_SECONDS: f64 = 29.53 * 86_400.0;
const PHASE_COUNT: u32 = 15;

#[unsafe(no_mangle)]
pub extern "C" fn moon_phase_index(unix_seconds: f64) -> u32 {
    let elapsed_seconds = unix_seconds - REFERENCE_NEW_MOON_UNIX_SECONDS;
    let cycle_seconds = elapsed_seconds.rem_euclid(LUNAR_CYCLE_SECONDS);
    ((cycle_seconds / (LUNAR_CYCLE_SECONDS / PHASE_COUNT as f64)) as u32) % PHASE_COUNT
}