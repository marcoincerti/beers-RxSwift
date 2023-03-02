//
//  elementViewCell.swift
//  beers
//
//  Created by Marco Incerti on 01/03/23.
//  Copyright © 2023 Marco. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public class elementViewCell: UITableViewCell {
    
    @IBOutlet weak var titleBeer: UILabel!
    @IBOutlet weak var descriptionBeer: UILabel!
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
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        downloadableImage = nil
        disposeBag = nil
    }

    deinit {
    }
    
}

