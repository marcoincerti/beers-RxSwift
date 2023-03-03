//
//  description.swift
//  beers_v1
//
//  Created by Marco Incerti on 03/03/23.
//

import UIKit
import RxSwift

class DescriptionController: UIViewController {

    
    @IBOutlet weak var descriptionBeer: UILabel!
    @IBOutlet weak var titleBeer: UILabel!
    @IBOutlet weak var imageBeer: UIImageView!
    
    var disposeBag: DisposeBag?
    let imageService = DefaultImageService.sharedImageService
    
    var downloadableImage: Observable<DownloadableImage>?{
        didSet{
            let disposeBag = DisposeBag()

            self.downloadableImage?
                .asDriver(onErrorJustReturn: DownloadableImage.offlinePlaceholder)
                .drive(imageBeer.rx.downloadableImageAnimated(CATransitionType.fade.rawValue))
                .disposed(by: disposeBag)

            self.disposeBag = disposeBag
        }
    }
    
    func updateUI(beer: Beer){
        downloadableImage = imageService.imageFromURL(beer.image_url!, reachabilityService: Dependencies.sharedDependencies.reachabilityService)
        titleBeer.text = beer.name
        descriptionBeer.text = beer.description
    }
    
    deinit {
    }
   
}

