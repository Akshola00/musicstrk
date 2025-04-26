#[starknet::contract]
pub mod MusicStrkGorvenance {
    use starknet::ContractAddress;
    use IMusicStrkGorvenance::IMusicStrkGorvenance;
    #[storage]
    struct Storage {
        admin: ContractAddress,
    }

    impl MusicStrkGorvenance of IMusicStrkGorvenance<ContractState> {
        
    }
}