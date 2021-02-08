use std::io::stdin;
use std::process::Command;

fn main() {
    let mut input = String::new();
    stdin().read_line(&mut input).unwrap();

    let command = input.trim();

    Command::new(command).spawn().unwrap();
}
