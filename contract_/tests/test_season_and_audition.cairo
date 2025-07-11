use contract_::audition::season_and_audition::{
    Audition, ISeasonAndAuditionDispatcher, ISeasonAndAuditionDispatcherTrait,
    ISeasonAndAuditionSafeDispatcher, ISeasonAndAuditionSafeDispatcherTrait, Season,
    SeasonAndAudition,
};
use openzeppelin::access::ownable::interface::IOwnableDispatcher;
use starknet::{ContractAddress, get_block_timestamp};

use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare,
    start_cheat_caller_address, stop_cheat_caller_address, spy_events, start_cheat_block_timestamp,
    stop_cheat_block_timestamp,
};

// Test account -> Owner
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

// Test account -> User
fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

fn NON_OWNER() -> ContractAddress {
    'NON_OWNER'.try_into().unwrap()
}

// Helper function to deploy the contract
fn deploy_contract() -> (
    ISeasonAndAuditionDispatcher, IOwnableDispatcher, ISeasonAndAuditionSafeDispatcher,
) {
    // declare the contract
    let contract_class = declare("SeasonAndAudition")
        .expect('Failed to declare counter')
        .contract_class();

    // serialize constructor
    let mut calldata: Array<felt252> = array![];

    OWNER().serialize(ref calldata);

    // deploy the contract
    let (contract_address, _) = contract_class
        .deploy(@calldata)
        .expect('Failed to deploy contract');

    let contract = ISeasonAndAuditionDispatcher { contract_address };
    let ownable = IOwnableDispatcher { contract_address };
    let safe_dispatcher = ISeasonAndAuditionSafeDispatcher { contract_address };

    (contract, ownable, safe_dispatcher)
}

// Helper function to create a default Season struct
fn create_default_season(season_id: felt252) -> Season {
    Season {
        season_id,
        genre: 'Pop',
        name: 'Summer Hits',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: false,
    }
}

// Helper function to create a default Audition struct
fn create_default_audition(audition_id: felt252, season_id: felt252) -> Audition {
    Audition {
        audition_id,
        season_id,
        genre: 'Pop',
        name: 'Live Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: false,
    }
}

#[test]
fn test_season_create() {
    let (contract, _, _) = deploy_contract();
    let mut spy = spy_events();

    // Define season ID
    let season_id: felt252 = 1;

    // Create default season
    let default_season = create_default_season(season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Season
    contract
        .create_season(
            season_id,
            default_season.genre,
            default_season.name,
            default_season.start_timestamp,
            default_season.end_timestamp,
            default_season.paused,
        );

    // READ Season
    let read_season = contract.read_season(season_id);

    assert!(read_season.season_id == season_id, "Failed to read season");
    assert!(read_season.genre == default_season.genre, "Failed to read season genre");
    assert!(read_season.name == default_season.name, "Failed to read season name");
    assert!(
        read_season.start_timestamp == default_season.start_timestamp,
        "Failed to read season start timestamp",
    );
    assert!(
        read_season.end_timestamp == default_season.end_timestamp,
        "Failed to read season end timestamp",
    );
    assert!(!read_season.paused, "Failed to read season paused");

    spy
        .assert_emitted(
            @array![
                (
                    contract.contract_address,
                    SeasonAndAudition::Event::SeasonCreated(
                        SeasonAndAudition::SeasonCreated {
                            season_id: default_season.season_id,
                            genre: default_season.genre,
                            name: default_season.name,
                        },
                    ),
                ),
            ],
        );

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_update_season() {
    let (contract, _, _) = deploy_contract();

    // Define season ID
    let season_id: felt252 = 1;

    // Create default season
    let default_season = create_default_season(season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Season
    contract
        .create_season(
            season_id,
            default_season.genre,
            default_season.name,
            default_season.start_timestamp,
            default_season.end_timestamp,
            default_season.paused,
        );

    // UPDATE Season
    let updated_season = Season {
        season_id,
        genre: 'Rock',
        name: 'Summer Hits',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: true,
    };
    contract.update_season(season_id, updated_season);

    // READ Updated Season
    let read_updated_season = contract.read_season(season_id);

    assert!(read_updated_season.genre == 'Rock', "Failed to update season");
    assert!(read_updated_season.name == 'Summer Hits', "Failed to update season name");
    assert!(read_updated_season.paused, "Failed to update season paused");

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_delete_season() {
    let (contract, _, _) = deploy_contract();

    // Define season ID
    let season_id: felt252 = 1;

    // Create default season
    let default_season = create_default_season(season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Season
    contract
        .create_season(
            season_id,
            default_season.genre,
            default_season.name,
            default_season.start_timestamp,
            default_season.end_timestamp,
            default_season.paused,
        );

    // DELETE Season
    contract.delete_season(season_id);

    // READ Deleted Season
    let deleted_season = contract.read_season(season_id);

    assert!(deleted_season.name == '', "Failed to delete season");
    assert!(deleted_season.genre == '', "Failed to delete season genre");
    assert!(deleted_season.start_timestamp == 0, "Failed to delete season start timestamp");
    assert!(deleted_season.end_timestamp == 0, "Failed to delete season end timestamp");
    assert!(!deleted_season.paused, "Failed to delete season paused");

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_audition() {
    let (contract, _, _) = deploy_contract();
    let mut spy = spy_events();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // READ Audition
    let read_audition = contract.read_audition(audition_id);

    assert!(read_audition.audition_id == audition_id, "Failed to read audition");
    assert!(read_audition.genre == default_audition.genre, "Failed to read audition genre");
    assert!(read_audition.name == default_audition.name, "Failed to read audition name");
    assert!(
        read_audition.start_timestamp == default_audition.start_timestamp,
        "Failed to read audition start timestamp",
    );
    assert!(
        read_audition.end_timestamp == default_audition.end_timestamp,
        "Failed to read audition end timestamp",
    );
    assert!(!read_audition.paused, "Failed to read audition paused");

    spy
        .assert_emitted(
            @array![
                (
                    contract.contract_address,
                    SeasonAndAudition::Event::AuditionCreated(
                        SeasonAndAudition::AuditionCreated {
                            audition_id: default_audition.audition_id,
                            season_id: default_audition.season_id,
                            genre: default_audition.genre,
                            name: default_audition.name,
                        },
                    ),
                ),
            ],
        );

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_update_audition() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: true,
    };
    contract.update_audition(audition_id, updated_audition);

    // READ Updated Audition
    let read_updated_audition = contract.read_audition(audition_id);

    assert!(read_updated_audition.genre == 'Rock', "Failed to update audition");
    assert!(read_updated_audition.name == 'Summer Audition', "Failed to update audition name");
    assert!(read_updated_audition.paused, "Failed to update audition paused");

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_delete_audition() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // DELETE Audition
    contract.delete_audition(audition_id);

    // READ Deleted Audition
    let deleted_audition = contract.read_audition(audition_id);

    assert!(deleted_audition.name == '', "Failed to delete audition");
    assert!(deleted_audition.genre == '', "Failed to delete audition genre");
    assert!(deleted_audition.start_timestamp == 0, "Failed to delete audition start timestamp");
    assert!(deleted_audition.end_timestamp == 0, "Failed to delete audition end timestamp");
    assert!(!deleted_audition.paused, "Failed to delete audition paused");

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_all_crud_operations() {
    let (contract, _, _) = deploy_contract();

    // Define season and audition IDs
    let season_id: felt252 = 1;
    let audition_id: felt252 = 1;

    // Create default season and audition
    let default_season = create_default_season(season_id);
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Season
    contract
        .create_season(
            season_id,
            default_season.genre,
            default_season.name,
            default_season.start_timestamp,
            default_season.end_timestamp,
            default_season.paused,
        );

    // READ Season
    let read_season = contract.read_season(season_id);

    println!("Default season is {}", default_season.paused);

    assert!(read_season.season_id == season_id, "Failed to read season");

    // UPDATE Season
    let updated_season = Season {
        season_id,
        genre: 'Rock',
        name: 'Summer Hits',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: true,
    };
    contract.update_season(season_id, updated_season);
    let read_updated_season = contract.read_season(season_id);

    assert!(read_updated_season.genre == 'Rock', "Failed to update season");
    assert!(read_updated_season.name == 'Summer Hits', "Failed to update season name");
    assert!(read_updated_season.paused, "Failed to update season paused");

    // DELETE Season
    contract.delete_season(season_id);
    let deleted_season = contract.read_season(season_id);

    assert!(deleted_season.name == 0, "Failed to delete season");

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // READ Audition
    let read_audition = contract.read_audition(audition_id);

    assert!(read_audition.audition_id == audition_id, "Failed to read audition");

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1675123200,
        paused: false //can't operate more functions if audition is paused 
    };
    contract.update_audition(audition_id, updated_audition);
    let read_updated_audition = contract.read_audition(audition_id);

    assert!(read_updated_audition.genre == 'Rock', "Failed to update audition");
    assert!(read_updated_audition.name == 'Summer Audition', "Failed to update audition name");
    assert!(!read_updated_audition.paused, "Failed to update audition paused");

    // DELETE Audition
    contract.delete_audition(audition_id);
    let deleted_audition = contract.read_audition(audition_id);

    assert!(deleted_audition.name == 0, "Failed to delete audition");

    // Stop prank
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_painc_only_owner_can_call_functions() {
    let (_, _, safe_dispatcher) = deploy_contract();

    // Start prank to simulate a non-owner calling the contract
    start_cheat_caller_address(safe_dispatcher.contract_address, USER());

    // Attempt to create a season
    match safe_dispatcher.create_season(1, 'Pop', 100, 1672531200, 1675123200, false) {
        Result::Ok(_) => panic!("Expected panic, but got success"),
        Result::Err(e) => assert(*e.at(0) == 'Caller is not the owner', *e.at(0)),
    }
}


#[test]
fn test_pause_audition() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);

    assert(is_audition_paused.paused, 'Audition is stil not paused');

    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_emission_of_event_for_pause_audition() {
    let (contract, _, _) = deploy_contract();
    let mut spy = spy_events();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);

    // Pause audition
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);

    assert(is_audition_paused.paused, 'Audition is stil not paused');

    spy
        .assert_emitted(
            @array![
                (
                    contract.contract_address,
                    SeasonAndAudition::Event::AuditionPaused(
                        SeasonAndAudition::AuditionPaused { audition_id: audition_id },
                    ),
                ),
            ],
        );

    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expect: 'Caller is not the owner')]
fn test_pause_audition_as_non_owner() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, NON_OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);

    assert(is_audition_paused.paused, 'Audition is stil not paused');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expect: 'Audition is already paused')]
fn test_pause_audition_twice_should_fail() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);
    stop_cheat_caller_address(contract.contract_address);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);

    assert(is_audition_paused.paused, 'Audition is stil not paused');

    // try to pause again
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expect: 'Cannot update paused audition')]
fn test_function_should_fail_after_pause_audition() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);

    assert(is_audition_paused.paused, 'Audition is stil not paused');

    //  try to perform function

    // Delete Audition
    contract.delete_audition(audition_id);

    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_resume_audition() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);
    assert(is_audition_paused.paused, 'Audition is stil not paused');

    //resume_audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.resume_audition(audition_id);

    //check that contract is no longer paused
    let is_audition_pausedv2 = contract.read_audition(audition_id);
    assert(!is_audition_pausedv2.paused, 'Audition is still paused');

    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expect: 'Caller is not the owner')]
fn test_attempt_resume_audition_as_non_owner() {
    let (contract, _, _) = deploy_contract();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);
    assert(is_audition_paused.paused, 'Audition is stil not paused');

    //resume_audition
    start_cheat_caller_address(contract.contract_address, NON_OWNER());
    contract.resume_audition(audition_id);

    //check that contract is no longer paused
    let is_audition_pausedv2 = contract.read_audition(audition_id);
    assert(!is_audition_pausedv2.paused, 'Audition is still paused');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_emission_of_event_for_resume_audition() {
    let (contract, _, _) = deploy_contract();

    let mut spy = spy_events();

    // Define audition ID and season ID
    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    // Create default audition
    let default_audition = create_default_audition(audition_id, season_id);

    // Start prank to simulate the owner calling the contract
    start_cheat_caller_address(contract.contract_address, OWNER());

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672531500,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);
    stop_cheat_caller_address(contract.contract_address);

    // Pause audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.pause_audition(audition_id);

    // check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);
    assert(is_audition_paused.paused, 'Audition is stil not paused');

    //resume_audition
    start_cheat_caller_address(contract.contract_address, OWNER());
    contract.resume_audition(audition_id);

    spy
        .assert_emitted(
            @array![
                (
                    contract.contract_address,
                    SeasonAndAudition::Event::AuditionResumed(
                        SeasonAndAudition::AuditionResumed { audition_id: audition_id },
                    ),
                ),
            ],
        );

    //check that contract is no longer paused
    let is_audition_pausedv2 = contract.read_audition(audition_id);
    assert(!is_audition_pausedv2.paused, 'Audition is still paused');

    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_end_audition() {
    let (contract, _, _) = deploy_contract();

    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    start_cheat_caller_address(contract.contract_address, OWNER());

    //  Add timestamp cheat
    let initial_timestamp: u64 = 1672531200;
    start_cheat_block_timestamp(contract.contract_address, initial_timestamp);

    let default_audition = create_default_audition(audition_id, season_id);

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition with future end time
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672617600, // Future time (24 hours later)
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);

    // Verify audition is not ended initially
    assert(!contract.is_audition_ended(audition_id), 'Should not be ended initially');

    // Pause audition (no need to call start_cheat_caller_address again)
    contract.pause_audition(audition_id);

    // Check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);
    assert(is_audition_paused.paused, 'Audition should be paused');

    // End the audition
    let end_result = contract.end_audition(audition_id);
    assert(end_result, 'End audition should succeed');

    // Check that audition has ended properly
    let audition_has_ended = contract.read_audition(audition_id);
    assert(contract.is_audition_ended(audition_id), 'Audition should be ended');
    assert(audition_has_ended.end_timestamp != 0, 'End timestamp should be set');
    assert(audition_has_ended.end_timestamp != 1672617600, 'Should not be original end time');

    // Check that the global contract is not paused
    let global_is_paused = contract.is_paused();
    assert(!global_is_paused, 'Global contract is paused');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_end_audition_as_non_owner() {
    let (contract, _, _) = deploy_contract();

    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    start_cheat_caller_address(contract.contract_address, OWNER());

    // Add timestamp cheat
    let initial_timestamp: u64 = 1672531200;
    start_cheat_block_timestamp(contract.contract_address, initial_timestamp);

    let default_audition = create_default_audition(audition_id, season_id);

    // CREATE Audition as owner
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition as owner
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672617600,
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);

    start_cheat_caller_address(contract.contract_address, NON_OWNER());

    contract.end_audition(audition_id);

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_emission_of_event_for_end_audition() {
    let (contract, _, _) = deploy_contract();
    let mut spy = spy_events();

    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    start_cheat_caller_address(contract.contract_address, OWNER());

    // Add timestamp cheat
    let initial_timestamp: u64 = 1672531200;
    start_cheat_block_timestamp(contract.contract_address, initial_timestamp);

    let default_audition = create_default_audition(audition_id, season_id);

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE Audition
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672617600, // Future time
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);

    // Pause audition
    contract.pause_audition(audition_id);

    // Check that the audition is paused
    let is_audition_paused = contract.read_audition(audition_id);
    assert(is_audition_paused.paused, 'Audition should be paused');

    // End the audition
    let end_result = contract.end_audition(audition_id);
    assert(end_result, 'End audition should succeed');

    // Check that audition has ended properly
    let audition_has_ended = contract.read_audition(audition_id);
    assert(contract.is_audition_ended(audition_id), 'Audition should be ended');
    assert(audition_has_ended.end_timestamp != 0, 'End timestamp should be set');

    // Check event emission
    spy
        .assert_emitted(
            @array![
                (
                    contract.contract_address,
                    SeasonAndAudition::Event::AuditionEnded(
                        SeasonAndAudition::AuditionEnded { audition_id: audition_id },
                    ),
                ),
            ],
        );

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expect: 'Cannot delete ended audition')]
fn test_end_audition_functionality() {
    let (contract, _, _) = deploy_contract();

    let audition_id: felt252 = 1;
    let season_id: felt252 = 1;

    start_cheat_caller_address(contract.contract_address, OWNER());

    // Set timestamp
    let initial_timestamp: u64 = 1672531200;
    start_cheat_block_timestamp(contract.contract_address, initial_timestamp);

    let default_audition = create_default_audition(audition_id, season_id);

    // CREATE Audition
    contract
        .create_audition(
            audition_id,
            season_id,
            default_audition.genre,
            default_audition.name,
            default_audition.start_timestamp,
            default_audition.end_timestamp,
            default_audition.paused,
        );

    // UPDATE with future end time
    let updated_audition = Audition {
        audition_id,
        season_id,
        genre: 'Rock',
        name: 'Summer Audition',
        start_timestamp: 1672531200,
        end_timestamp: 1672617600, // Future time
        paused: false,
    };
    contract.update_audition(audition_id, updated_audition);

    // Verify audition is not ended initially
    assert(!contract.is_audition_ended(audition_id), 'Should not be ended initially');

    // End the audition
    let end_result = contract.end_audition(audition_id);
    assert(end_result, 'End audition should succeed');

    // Check state after ending
    let audition_after_end = contract.read_audition(audition_id);

    // check that the audition has ended
    assert(contract.is_audition_ended(audition_id), 'Audition should be ended');

    assert(contract.is_audition_ended(audition_id), 'Audition should be ended');
    assert(audition_after_end.end_timestamp != 0, 'End timestamp should be set');
    assert(audition_after_end.end_timestamp != 1672617600, 'Should not be original end time');
    assert(audition_after_end.end_timestamp != 0, 'End timestamp should not be 0');

    //  Test restrictions on ended audition
    //try to delete
    contract.delete_audition(audition_id);

    println!("All tests passed!");

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}
