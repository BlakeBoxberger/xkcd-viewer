//
//  ViewController.swift
//  xkcd viewer (Experion)
//
//  Created by Blake Boxberger on 6/6/21.
//

import UIKit
import SDWebImage

class XkcdMainViewController: UIViewController {
    @IBOutlet weak var comicTitleLabel: UILabel!
    @IBOutlet weak var comicSecondaryLabel: UILabel!
    @IBOutlet weak var comicImageView: UIImageView!
    
    private let animationsDuration: TimeInterval = 0.33
    private var maxNumOfComics: Int!
    private var currentComic: XckdComic? = nil
    private var comic: XckdComic? {
        didSet {
            if let comic = comic {
                let comicUrl = URL(string: comic.img)
                
                // Make sure we're on the main queue when updating UI
                DispatchQueue.main.async { [unowned self] in
                    // Set image immediately, as it needs to be retrieved from a server
                    let placeholderImage = comicImageView.image // Use previous image as placeholder
                    comicImageView.sd_setImage(with: comicUrl, placeholderImage: placeholderImage, options: [.refreshCached, .continueInBackground], completed: nil)
                    
                    // Animate out comic content
                    UIView.animate(withDuration: animationsDuration, delay: 0.0, options: [.curveEaseInOut], animations: {
                        comicImageView.alpha = 0
                        comicTitleLabel.alpha = 0
                        comicSecondaryLabel.alpha = 0
                    }, completion: { _ in
                        // Set title label
                        comicTitleLabel.text = comic.title
                        
                        // Set secondary label – Display "⭐️ Current Comic" if it is the current comic and displays the date the comic was created
                        comicSecondaryLabel.text = "\(isDisplayingCurrentComic ? "⭐️ Current Comic – " : "")\(comic.day)/\(comic.month)/\(comic.year)"
                        
                        // Animate in comic content
                        UIView.animate(withDuration: animationsDuration, delay: 0.0, options: [.curveEaseInOut]) {
                            comicImageView.alpha = 1.0
                            comicTitleLabel.alpha = 1.0
                            comicSecondaryLabel.alpha = 1.0
                        }
                    })
                }
            }
        }
    }
    private var isDisplayingComicContent: Bool = true {
        didSet {
            if isDisplayingComicContent {
            
            } else {
                UIView.animate(withDuration: animationsDuration, delay: 0.0, options: [.curveEaseInOut], animations: { [unowned self] in
                    comicImageView.isHidden = false
                    comicTitleLabel.isHidden = false
                    comicSecondaryLabel.isHidden = false
                }, completion: nil)
            }
        }
    }
    
    private var isDisplayingCurrentComic: Bool {
        guard let comic = comic, let currentComic = currentComic else {
            return false
        }
        return comic.img == currentComic.img
    }
    
    private var isComicViewRotated: Bool = false
    private let rotationScale: CGFloat = 1.50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable user interaction on the comicImageView even though it's already enabled in the storyboard
        comicImageView.isUserInteractionEnabled = true
        
        // Hide comic content before it's displayed
        comicImageView.alpha = 0
        comicTitleLabel.alpha = 0
        comicSecondaryLabel.alpha = 0
        
        _fetchCurrentComic()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Begin listening for device orientation notifications
        NotificationCenter.default.addObserver(self, selector: #selector(_deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop listening for device orientation notifications
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    
    @objc private func _deviceOrientationDidChange() {
        switch UIDevice.current.orientation {
        case .portrait:
            _animateComicImageViewWith(.identity)
            isComicViewRotated = false
        case .landscapeLeft:
            _animateComicImageViewWith(.identity.rotated(by: .pi/2).scaledBy(x: rotationScale, y: rotationScale))
            isComicViewRotated = true
        case .landscapeRight:
            _animateComicImageViewWith(.identity.rotated(by: -.pi/2).scaledBy(x: rotationScale, y: rotationScale))
            isComicViewRotated = true
        case .faceUp, .faceDown, .portraitUpsideDown, .unknown:
            fallthrough
        @unknown default:
            // Do nothing
            break
        }
    }
    
    private func _animateComicImageViewWith(_ transform: CGAffineTransform) {
        UIView.animate(withDuration: animationsDuration, delay: 0, options: [.curveEaseInOut], animations: { [unowned self] in
            comicImageView.transform = transform
        }, completion: nil)
    }
    
    private func _fetchCurrentComic() {
        guard let currentComicURL = URL(string: "https://xkcd.com/info.0.json") else {
            print("\(#file), Line: \(#line) - Could not create current comic URL.")
            return
        }
        
        let task = URLSession.shared.xckdComicTask(with: currentComicURL) { fetchedComic, response, error in
            if let fetchedComic = fetchedComic {
                self.currentComic = fetchedComic
                self.comic = fetchedComic
                self.maxNumOfComics = fetchedComic.num
            }
        }
        task.resume()
    }

    @IBAction func showRandomComicButtonTapped(_ sender: UIButton) {
        let randomComicNumber = Int.random(in: 1...maxNumOfComics)
        let randomComicUrl = URL(string: "https://xkcd.com/\(randomComicNumber)/info.0.json")
        
        guard let randomComicUrl = randomComicUrl else {
            print("\(#file), Line: \(#line) - Could not create random comic URL.")
            return
        }
        
        let task = URLSession.shared.xckdComicTask(with: randomComicUrl) { fetchedComic, response, error in
            if let fetchedComic = fetchedComic {
                self.comic = fetchedComic
            }
        }
        task.resume()
    }
    
    @IBAction func helpButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "", message: "Tap or rotate your device to expand comics, and tap the random comic button for a new comic!\n\nPretty easy, huh? :)\n\nThis app was created for assessment purposes only. Please do not reuse or modify this code in your own projects.\n\nThank you!\n\nMade with ❤️ by Blake.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func comicImageViewTapped(_ sender: UITapGestureRecognizer) {
        if isComicViewRotated {
            _animateComicImageViewWith(.identity)
        } else {
            _animateComicImageViewWith(.identity.rotated(by: .pi/2).scaledBy(x: rotationScale, y: rotationScale))
        }
        
        isComicViewRotated.toggle()
    }
}

