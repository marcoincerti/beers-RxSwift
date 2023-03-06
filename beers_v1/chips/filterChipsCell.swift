//
//  filterChipsCell.swift
//  beers_v1
//
//  Created by Marco Incerti on 03/03/23.
//

import UIKit
import Differentiator


class filterChipsCell: UICollectionViewCell {
    @IBOutlet var btn: UIButton!
    
    var activated : Bool = false
    
    func setLabel(label:String) {
        btn.setTitle(label, for: .normal)
        btn.tintColor = .gray
        btn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let btnsendtag: UIButton = sender
        if self.activated {
            btnsendtag.tintColor = .gray
            
        }else{
            btnsendtag.tintColor = .orange
        }
        self.activated.toggle()
    }
}
