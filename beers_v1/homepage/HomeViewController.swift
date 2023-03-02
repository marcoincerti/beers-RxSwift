//
//  ViewController.swift
//  beers
//
//  Created by Marco Incerti on 01/03/23.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

extension UIScrollView {
    func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
        self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}

class ViewController: UIViewController {
    var disposeBag = DisposeBag()
}

class HomeViewController: ViewController, UITableViewDelegate {
    static let startLoadingOffset: CGFloat = 20.0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Beer>>(
        configureCell: { (_, tv, ip, beer: Beer) in
            let cell = tv.dequeueReusableCell(withIdentifier: "elementCell")! as? elementViewCell
            cell!.titleBeer.text = beer.name
            cell!.descriptionBeer.text = beer.description
            cell!.downloadableImage = cell!.imageService.imageFromURL(beer.image_url!, reachabilityService: Dependencies.sharedDependencies.reachabilityService)
            return cell!
        },
        titleForHeaderInSection: { dataSource, sectionIndex in
            let section = dataSource[sectionIndex]
            return section.items.count > 0 ? "Beers (\(section.items.count))" : "No beers found"
        }
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let titleLabel = UILabel()
        titleLabel.text = "Beer"
        titleLabel.textColor = .white
        
        let titleLabel2 = UILabel()
        titleLabel2.text = "Box"
        titleLabel2.font = titleLabel2.font.bold
        titleLabel2.textColor = .white
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, titleLabel2])
        stackView.spacing = 3
        stackView.alignment = .center

        navigationItem.titleView = stackView
        
        let tableView: UITableView = self.tableView
        tableView.register(UINib(nibName: "elementCell", bundle: nil), forCellReuseIdentifier: "elementCell")
        tableView.rowHeight = 120

        
        let loadNextPageTrigger: (Driver<BeerSearchState>) -> Signal<()> =  { state in
            tableView.rx.contentOffset.asDriver()
                .withLatestFrom(state)
                .flatMap { state in
                    return tableView.isNearBottomEdge(edgeOffset: 20.0) && !state.shouldLoadNextPage
                        ? Signal.just(())
                        : Signal.empty()
                }
        }

        let activityIndicator = ActivityIndicator()

        let searchBar: UISearchBar = self.searchBar

        let state = beersSearch(
            searchText: searchBar.rx.text.orEmpty.changed.asSignal().throttle(.milliseconds(300)),
            loadNextPageTrigger: loadNextPageTrigger,
            performSearch: { URL in
                BeersSearchAPI.sharedAPI.loadSearchURL(URL)
                    .trackActivity(activityIndicator)
            })
        
        state
            .map { $0.beers }
            .distinctUntilChanged()
            .map { [SectionModel(model: "Beers", items: $0.value)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)


        tableView.rx.contentOffset
            .subscribe { _ in
                if searchBar.isFirstResponder {
                    _ = searchBar.resignFirstResponder()
                }
            }
            .disposed(by: disposeBag)

        // so normal delegate customization can also be used
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

    }

    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        25
    }

    deinit {
        // I know, I know, this isn't a good place of truth, but it's no
        self.navigationController?.navigationBar.backgroundColor = nil
    }
}
