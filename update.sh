apt update && apt upgrade -y
rustup update
gem update --system && gem update && bundle update
cd wasm-client
cargo update
cargo build --release
cd ..
cd bin
./start-wasm-https-background.sh