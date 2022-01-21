//
//  UploadSongViewController.swift
//  Toner
//
//  Created by Apoorva Gangrade on 26/04/21.
//  Copyright © 2021 Users. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Alamofire
import AVFoundation

class UploadSongViewController: UIViewController {
    @IBOutlet weak var lblSongName: UILabel!
    @IBOutlet weak var txtSongName: UITextField!
    @IBOutlet weak var txtStation: UITextField!
    @IBOutlet weak var txtReleaseDate: UITextField!
    @IBOutlet weak var txtStatus: UITextField!
    @IBOutlet weak var txtAlbum: UITextField!
    @IBOutlet weak var txtPrice: UITextField!
    @IBOutlet weak var txtAllowDownload: UITextField!
    @IBOutlet weak var imgSongThumnilImg: RCustomImageView!
    @IBOutlet weak var btnUploadSongBottomLayout: NSLayoutConstraint!
    
    var genreData = [TopGenreModel]()
    var arrAblum = [AlbumModel]()
    var arrStatus = ["Yes","No"]
    
    var activityIndicator: NVActivityIndicatorView!
    var url : URL?
    var imagData =  Data()
    var songData_ = Data()
    var songName = ""
    var album_id = ""
    var genre_id = ""
    var release_date = ""
    var price = ""
    var allow_download = ""
    var status = ""
    
    let stationPicker = UIPickerView()
    let statusPicker = UIPickerView()
    let releaseDatePicker = UIDatePicker()
    let AlbumPicker = UIPickerView()
    let allDownloadPicker = UIPickerView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        let playerItem = AVPlayerItem(url: url!)
        let metadataList = playerItem.asset.commonMetadata

        for item in metadataList {
            if let stringValue = item.value as? String {
                if item.commonKey?.rawValue == "title" {
                    print(stringValue)
                    lblSongName.text = stringValue
                    songName = stringValue
                    txtSongName.text = stringValue
                }
            }
        }
        genreData = appD.genreData
        getArtistAlbumData()
        txtPrice.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        btnUploadSongBottomLayout.constant = TonneruMusicPlayer.shared.isMiniViewActive ? 100 : 0//.player?.isPlaying ?? false ? 100 : 0
    }
    
    func setUI() {
        activityIndicator = addActivityIndicator()
        self.view.addSubview(activityIndicator)
        self.setNavigationBar(title: "Upload Song", isBackButtonRequired: true, isTransparent: false)
        txtStation.inputView = stationPicker
        stationPicker.delegate = self
        stationPicker.dataSource = self
        txtStatus.inputView = statusPicker
        statusPicker.delegate = self
        statusPicker.dataSource = self
        txtAlbum.inputView = AlbumPicker
        AlbumPicker.delegate = self
        AlbumPicker.dataSource = self
        txtAllowDownload.inputView = allDownloadPicker
        allDownloadPicker.delegate = self
        allDownloadPicker.dataSource = self
        
        self.txtReleaseDate.setInputViewDatePicker(target: self, selector: #selector(tapDone)) //1
        if #available(iOS 13.4, *) {
            releaseDatePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBAction func btnPublishAction(_ sender: UIButton) {
        if txtSongName.text?.isEmpty ?? false{
            showAlert(message: "Please enter song name")
            return
        }else if txtStation.text?.isEmpty ?? false{
            showAlert(message: "Please select station")
            return
        }else if txtReleaseDate.text?.isEmpty ?? false{
            showAlert(message: "Please enter release date")
            return
        }else if txtStatus.text?.isEmpty ?? false{
            showAlert(message: "Please select status")
            return
        }else if txtAlbum.text?.isEmpty ?? false{
            showAlert(message: "Please select album")
            return
        }else if txtAllowDownload.text?.isEmpty ?? false{
            showAlert(message: "Please select allow download")
            return
        }

        uploadImage()
    }
    @IBAction func btnSelectImgAction(_ sender: UIButton) {
        presentPhoto()
    }

    @objc func tapDone() {
        if let datePicker = self.txtReleaseDate.inputView as? UIDatePicker {
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            } else {
                // Fallback on earlier versions
            }
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd"
            self.txtReleaseDate.text = dateformatter.string(from: datePicker.date) //2-4
            release_date = dateformatter.string(from: datePicker.date)
        }
        self.txtReleaseDate.resignFirstResponder() // 2-5
    }
}

extension UploadSongViewController : UIDocumentMenuDelegate,UIDocumentPickerDelegate,UINavigationControllerDelegate{
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
            return
        }
        print("import result : \(myURL)")
        songData_ = try! Data(contentsOf: myURL)
        print(songData_)
    }
    
    //    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
    //        documentPicker.delegate = self
    //        present(documentPicker, animated: true, completion: nil)
    //    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}

//MARK:- Change Image
extension UploadSongViewController:UIImagePickerControllerDelegate{
    func presentPhoto() {
        let actionSheet = UIAlertController(title: "Add Image",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentCamera1()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            
            //   self?.presentPhotoPicker1()
            let photoPicker = UIImagePickerController()
            photoPicker.delegate = self
            photoPicker.sourceType = .photoLibrary
            self!.present(photoPicker, animated: true, completion: nil)
            
        }))
        self.present(actionSheet, animated: true)
        actionSheet.view.superview?.isUserInteractionEnabled = true
        actionSheet.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTapOutside)))
    }
    @objc func dismissOnTapOutside(){
        self.dismiss(animated: true, completion: nil)
    }
    func presentCamera1() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            imgSongThumnilImg.image = selectedImage
            imagData = selectedImage.jpegData(compressionQuality: 0.5)!
        }
        
        //dismiss(animated: true, completion: nil)
        dismiss(animated: true) {
            //self.uploadImage()
            
        }
    }
    
    func uploadImage() {
        self.activityIndicator.startAnimating()
        if !NetworkReachabilityManager()!.isReachable{
            return
        }
        let url = "https://tonnerumusic.com/api/v1/uploadsong"
        var headers = HTTPHeaders()
        headers = ["Content-type": "multipart/form-data"]
        let price = txtPrice.text
        self.songName = txtSongName.text ?? ""
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(self.imagData, withName: "image", fileName: "\(Date().timeIntervalSince1970).jpg", mimeType: "image/jpg")
            
            let userID:String = UserDefaults.standard.fetchData(forKey: .userId) //"53"
            multipartFormData.append(self.songName.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"song_name")
            multipartFormData.append(userID.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"user_id")
            multipartFormData.append(self.album_id.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"album_id")
            multipartFormData.append(self.genre_id.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"genre_id")
            multipartFormData.append(self.release_date.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"release_date")
            multipartFormData.append(price!.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"price")
            multipartFormData.append(self.allow_download.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"allow_download")
            multipartFormData.append(self.status.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"status")
            // multipartFormData.append(self.songData_ as Data, withName: "track", fileName: self.songName, mimeType: "audio/mp3")
            multipartFormData.append( (self.url!), withName: "track")
            /*
             "path", "filesize", "duration",
             */
            //            multipartFormData.append(self.songName.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data(), withName :"track")
            
        }, to: url,method:HTTPMethod.post,
                         headers:headers,
                         encodingCompletion: { encodingResult in
            DispatchQueue.main.async {
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        print(response)
                        self.activityIndicator.stopAnimating()
                        self.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    print(error)
                    self.showAlert(message: "Song is not uploaded, Please try again later.")
                    self.activityIndicator.stopAnimating()
                }
            }
        })
    }
    
    func callWebserviceArtistPaymentSong(song_id:String) {
        let user:String = UserDefaults.standard.fetchData(forKey: .userId)
        self.activityIndicator.startAnimating()
        let apiURL = "https://tonnerumusic.com/api/v1/paymentsong"
        let urlConvertible = URL(string: apiURL)!
        Alamofire.request(urlConvertible,
                          method: .post,
                          parameters: [
                            "song_id": song_id,
                            "user_id": UserDefaults.standard.fetchData(forKey: .userId)
                          ] as [String: String])
        
            .validate().responseJSON { (response) in
                
                guard response.result.isSuccess else {
                    self.tabBarController?.view.makeToast(message: Message.apiError)
                    self.activityIndicator.stopAnimating()
                    return
                }
                
                let resposeJSON = response.value as? NSDictionary ?? NSDictionary()
                print(resposeJSON)
                self.activityIndicator.stopAnimating()
                
                
                //            let results = resposeJSON["text"] as? String ?? ""
                //
                //            if results == "Follow"{
                //                self.tabBarController?.view.makeToast(message: "You have successfully unfollow the artist.")
                //                self.followButton.isSelected = false
                //                self.artistDetailsData?.followStatus = 0
                //            }else{
                //                self.tabBarController?.view.makeToast(message: "You have successfully follow the artist.")
                //                self.followButton.isSelected = true
                //                self.artistDetailsData?.followStatus = 1
                //            }
                //
                //            NotificationCenter.default.post(name: .UpdateFollowingList, object: nil)
                //
                //            self.tableView.reloadData()
            }
    }
    func getArtistAlbumData(){
        self.activityIndicator.startAnimating()
        let artistId: String = UserDefaults.standard.fetchData(forKey: .userId)
        let apiURL = "https://tonnerumusic.com/api/v1/artist_album"
        let urlConvertible = URL(string: apiURL)!
        Alamofire.request(urlConvertible,
                          method: .post,
                          parameters: [
                            "artist_id": artistId
                          ] as [String: String])
            .validate().responseJSON { (response) in
                
                guard response.result.isSuccess else {
                    self.tabBarController?.view.makeToast(message: Message.apiError)
                    self.activityIndicator.stopAnimating()
                    return
                }
                
                let resposeJSON = response.value as? NSDictionary ?? NSDictionary()
                print(resposeJSON)
                let allAlbums = resposeJSON["albums"] as? NSArray ?? NSArray()
                if self.arrAblum.count>0{
                    self.arrAblum.removeAll()
                }
                for objAlbum in allAlbums{
                    let obj = objAlbum as? NSDictionary ?? NSDictionary()
                    var currentData = AlbumModel()
                    currentData.id = obj["id"] as? String ?? ""
                    currentData.image = obj["image"] as? String ?? ""
                    currentData.name = obj["name"] as? String ?? ""
                    currentData.totalsongs = obj["totalsongs"] as? Int ?? 0
                    currentData.user_id = obj["user_id"] as? String ?? ""
                    self.arrAblum.append(currentData)
                }
                if self.arrAblum.count == 0 {
                    self.txtAlbum.isUserInteractionEnabled = false
                }else{
                    self.txtAlbum.isUserInteractionEnabled = true
                }
                self.AlbumPicker.reloadAllComponents()
                self.activityIndicator.stopAnimating()
            }
    }
}

// MARK: UIPickerView Delegation
extension UploadSongViewController : UIPickerViewDelegate, UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == stationPicker{
            return genreData.count
        }else if pickerView == AlbumPicker{
            return arrAblum.count
        }else if pickerView == allDownloadPicker{
            return arrStatus.count
        }else{
            return self.arrStatus.count
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == stationPicker{
            txtStation.text = genreData[row].name
            genre_id = genreData[row].id
            return genreData[row].name
        }else if pickerView == AlbumPicker{
            txtAlbum.text = arrAblum[row].name
            album_id = arrAblum[row].id
            return arrAblum[row].name
        }else if pickerView == allDownloadPicker{
            txtAllowDownload.text =  arrStatus[row]
            let download = arrStatus[row]
            if download == "Yes"{
                allow_download = "1"
            }else{
                allow_download = "0"
            }
            return arrStatus[row]
        }else{
            txtStatus.text =  arrStatus[row]
            let statusValue = arrStatus[row]
            if statusValue == "Yes"{
                status = "1"
            }else{
                status = "0"
            }
            return arrStatus[row]
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == stationPicker{
            txtStation.text = genreData[row].name
            genre_id = genreData[row].id
        }else if pickerView == AlbumPicker{
            txtAlbum.text = arrAblum[row].name
            album_id = arrAblum[row].id
        } else if pickerView == allDownloadPicker{
            txtAllowDownload.text =  arrStatus[row]
            let download = arrStatus[row]
            if download == "Yes"{
                allow_download = "1"
            }else{
                allow_download = "0"
            }
        }else{
            txtStatus.text =  arrStatus[row]
            let statusValue = arrStatus[row]
            if statusValue == "Yes"{
                status = "1"
            }else{
                status = "0"
            }
        }
    }
}

extension UITextField {
    
    func setInputViewDatePicker(target: Any, selector: Selector) {
        // Create a UIDatePicker object and assign to inputView
        let screenWidth = UIScreen.main.bounds.width
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))//1
        datePicker.datePickerMode = .date //2
        // iOS 14 and above
        if #available(iOS 14, *) {// Added condition for iOS 14
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.sizeToFit()
        }
        self.inputView = datePicker //3
        
        // Create a toolbar and assign it to inputAccessoryView
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0)) //4
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) //5
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: #selector(tapCancel)) // 6
        let barButton = UIBarButtonItem(title: "Done", style: .plain, target: target, action: selector) //7
        toolBar.setItems([cancel, flexible, barButton], animated: false) //8
        self.inputAccessoryView = toolBar //9
    }
    
    @objc func tapCancel() {
        self.resignFirstResponder()
    }
    
}
extension UploadSongViewController : UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtPrice{
            let dotsCount = textField.text!.components(separatedBy: ".").count - 1
            if dotsCount > 0 && (string == ".") {
                return false
            }
            //               if string == "," {
            //                  textField.text! += "."
            //                  return false
            //              }
            return true
        }
        return true
    }
}
