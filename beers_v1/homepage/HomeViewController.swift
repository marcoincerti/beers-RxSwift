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
import FloatingPanel

class ViewController: UIViewController {
    var disposeBag = DisposeBag()
}

class HomeViewController: ViewController, UITableViewDelegate, FloatingPanelControllerDelegate {
    
    static let startLoadingOffset: CGFloat = 20.0
    var descriptionMapFPC: FloatingPanelController!
    var descriptionController: DescriptionController!
    
    //of operator is used to create an observables array or an observable of individual type
    let labels = Observable.of(["Blonde", "Tipo B", "C", "D", "E", "F", "G", "H"])
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //creare un datasource anche per le chips
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
        createUI()
        
        let tableView: UITableView = self.tableView
        tableView.register(UINib(nibName: "elementCell", bundle: nil), forCellReuseIdentifier: "elementCell")
        tableView.rowHeight = 120
        
        let collectionView: UICollectionView = self.collectionView
        collectionView.register(UINib(nibName: "chipsView", bundle: nil), forCellWithReuseIdentifier: "chipsView")
        
        labels
            .bind(to: collectionView.rx.items) { (collectionView: UICollectionView, index: Int, element: String) in
                print(element)
                let indexPath = IndexPath(item: index, section: 0)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chipsView", for: indexPath) as? filterChipsCell
                cell!.setLabel(label: element)
                return cell!
            }.disposed(by: disposeBag)
        
        
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
            searchText: searchBar.rx.text.orEmpty.changed.asSignal().throttle(.milliseconds(500)),
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
        
        tableView.rx.modelSelected(Beer.self)
            .subscribe(onNext: { beer in
                //Open
                //print(beer)
                self.descriptionMapFPC.set(contentViewController: self.descriptionController)
                self.descriptionController.updateUI(beer: beer)
                self.descriptionMapFPC.show(animated: true, completion: {
                    self.descriptionMapFPC.didMove(toParent: self)
                })
                //UIApplication.shared.open(repository.url)
            })
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
        
        collectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
    }
    
    func createUI(){
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
        
        messageView.layer.cornerRadius = 15
        
        descriptionMapFPC = FloatingPanelController()
        descriptionMapFPC.delegate = self // Optional
        descriptionMapFPC.layout = DescriptionFloatingPanelLayout()
        descriptionMapFPC.addPanel(toParent: self)
        descriptionMapFPC.hide(animated: false, completion: nil)
        
        descriptionController = DescriptionController(nibName: "descriptionView", bundle: .main)
        
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

extension UIScrollView {
    func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
        self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}


class DescriptionFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .half
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.3, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: -34, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
}
