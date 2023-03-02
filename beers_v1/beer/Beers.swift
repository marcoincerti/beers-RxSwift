//
//  Beers.swift
//  beers_v1
//
//  Created by Marco Incerti on 01/03/23.
//

import RxSwift
import RxCocoa
import RxFeedback
import Foundation

enum BeerCommand {
    case changeSearch(text: String)
    case loadMoreItems
    case BeerResponseReceived(SearchBeersResponse)
}

struct BeerSearchState {
    // control
    var searchText: String
    var shouldLoadNextPage: Bool
    var currentPage: Int
    var beers: Version<[Beer]> 
    var nextURL: URL?
    var failure: BeersServiceError?

    init(searchText: String, url: String) {
        self.searchText = searchText
        shouldLoadNextPage = true
        beers = Version([])
        currentPage = 1
        nextURL = URL(string: url)
        failure = nil
    }
}

extension BeerSearchState {
    static let initial = BeerSearchState(searchText: "", url: "https://api.punkapi.com/v2/beers?page=1&per_page=25")

    static func reduce(state: BeerSearchState, command: BeerCommand) -> BeerSearchState {
        switch command {
            //se il testo cambia ritorna un oggetto nuovo, o se no lo cambia
        case .changeSearch(let text):
            return text.isEmpty ? BeerSearchState(searchText: text, url: "https://api.punkapi.com/v2/beers?page=1&per_page=25").mutateOne { $0.failure = state.failure } : BeerSearchState(searchText: text.replacingOccurrences(of: " ", with: "+"), url: "https://api.punkapi.com/v2/beers?page=1&per_page=25&beer_name=\(text.replacingOccurrences(of: " ", with: "+"))").mutateOne { $0.failure = state.failure }
            
        case .BeerResponseReceived(let result):
            switch result {
            case let .success((beers)):
                return state.mutate {
                    $0.beers = Version($0.beers.value + beers)
                    $0.shouldLoadNextPage = false
                    $0.currentPage = $0.currentPage + 1
                    $0.nextURL = $0.searchText.isEmpty ? URL(string: "https://api.punkapi.com/v2/beers?page=\($0.currentPage)&per_page=25") :
                    URL(string: "https://api.punkapi.com/v2/beers?page=\($0.currentPage)&per_page=25&beer_name=\($0.searchText)")
                    $0.failure = nil
                }
            case let .failure(error):
                return state.mutateOne { $0.failure = error }
            }
        case .loadMoreItems:
            return state.mutate {
                if $0.failure == nil {
                    $0.shouldLoadNextPage = true
                }
            }
        }
    }
}

struct BeerQuery: Equatable {
    let searchText: String;
    let shouldLoadNextPage: Bool;
    let nextURL: URL?
}


func beersSearch(
        searchText: Signal<String>,
        loadNextPageTrigger: @escaping (Driver<BeerSearchState>) -> Signal<()>,
        performSearch: @escaping (URL) -> Observable<SearchBeersResponse>
    ) -> Driver<BeerSearchState> {


        
        //Quando cerco
    let searchPerformerFeedback: (Driver<BeerSearchState>) -> Signal<BeerCommand> = react(
        request: { (state) in
            BeerQuery(searchText: state.searchText, shouldLoadNextPage: state.shouldLoadNextPage, nextURL: state.nextURL)
        },
        effects: { query -> Signal<BeerCommand> in
                if !query.shouldLoadNextPage {
                    return Signal.empty()
                }
            //Devo modificare qua, controlla se è vuoto e poi consegna il url su cui fare la chiamata
                //if query.searchText.isEmpty {
                    //return Signal.just(BeerCommand.BeerResponseReceived(.success((beers: [], nextURL: nil))))
                //}

                guard let nextURL = query.nextURL else {
                    return Signal.empty()
                }

                return performSearch(nextURL)
                    .asSignal(onErrorJustReturn: .failure(BeersServiceError.networkError))
                    .map(BeerCommand.BeerResponseReceived)
            }
    )

    // this is degenerated feedback loop that doesn't depend on output state
    let inputFeedbackLoop: (Driver<BeerSearchState>) -> Signal<BeerCommand> = { state in
        let loadNextPage = loadNextPageTrigger(state).map { _ in BeerCommand.loadMoreItems }
        let searchText = searchText.map(BeerCommand.changeSearch)

        return Signal.merge(loadNextPage, searchText)
    }

    // Create a system with two feedback loops that drive the system
    // * one that tries to load new pages when necessary
    // * one that sends commands from user input
    return Driver.system(
        initialState: BeerSearchState.initial,
        reduce: BeerSearchState.reduce,
        feedback: searchPerformerFeedback, inputFeedbackLoop
    )
}

extension BeerSearchState {
    var isOffline: Bool {
        guard let failure = self.failure else {
            return false
        }

        if case .offline = failure {
            return true
        }
        else {
            return false
        }
    }
    
}

extension BeerSearchState: Mutable {

}
