//
//  MyDownloadViewController.swift
//  Toner
//
//  Created by User on 31/10/20.
//  Copyright © 2020 Users. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Alamofire
class MyDownloadViewController: UIViewController, TonneruDownloadButtonDelegate {

    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: NVActivityIndicatorView!
    
    var offlineDataArray = [ContentDetailsEntityModel]()
    var reDownloadArray = [SongModel]()
    var playAllButton : UIBarButtonItem!
    var downloadAllButton : UIBarButtonItem!
    var newSongCounter = 0
    var downloadSongCounter = 0
    var isDownloadEnable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = ThemeColor.backgroundColor
        self.setNavigationBar(title: "MY DOWNLOADS", isBackButtonRequired: true, isTransparent: false)
        activityIndicator = addActivityIndicator()
        self.view.addSubview(activityIndicator)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.register(UINib(nibName: "DownloadTableViewCell", bundle: nil), forCellReuseIdentifier: "DownloadTableViewCell")
        tableView.register(UINib(nibName: "SongInPlayListTVCell", bundle: nil), forCellReuseIdentifier: "SongInPlayListTVCell")

        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationController?.navigationBar.tintColor = ThemeColor.buttonColor
        playAllButton = UIBarButtonItem(image: UIImage.init(named: "playAll"), style: .plain, target:self, action: #selector(playAllClicked))
        downloadAllButton = UIBarButtonItem(image: UIImage.init(named: "downloadAll"), style: .plain, target: self, action: #selector(downloadAllClicked))
        self.navigationItem.rightBarButtonItems = [playAllButton, downloadAllButton]
        
        self.fetchSongFromServer()
    }

    @objc func downloadAllClicked(){
        let allDownloadedContent = ContentDetailsEntity.fetchData()
        if reDownloadArray.count > 0 {
            activityIndicator.startAnimating()
            isDownloadEnable = true
            for reDownload in reDownloadArray {
                if allDownloadedContent.filter({$0.songID == reDownload.song_id}).count > 0 {
                    print("Already Existing")
                }else{
                    self.newSongCounter = self.newSongCounter + 1
                    print("New Song for local")
                    downloadAudio(data: reDownload)
                }
            }
        }else{
            showAlert(message: "You do not have any song inside re download section.")
        }
    }
    
    @objc func playAllClicked(){
        var songModel = [SongModel]()
        for data in self.offlineDataArray{
            let songData = SongModel(song_id: data.songID, song_name: data.songName, image: data.songImage, path: data.songPath, filetype: data.fileType, filesize: data.fileSize, duration: data.songDuration, artist_name: data.artistName, artistImage: data.artistImage)
            songModel.append(songData)
        }
        if songModel.count > 0{
            resetPlayer()
            TonneruMusicPlayer.shared.initialize()
            TonneruMusicPlayer.shared.playSong(data: songModel, index: 0)
        }else{
            showAlert(message: "You do not have any song in offline section.")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: (TonneruMusicPlayer.shared.isMiniViewActive) ? 56 : 0))
    }

    func fetchSongFromServer(){
        activityIndicator.startAnimating()
        Alamofire.request(URL(string: "https://tonnerumusic.com/api/v1/mydownloads")!,
                          method: .post,
                          parameters: [
                            "user_id": UserDefaults.standard.fetchData(forKey: .userId)
                          ] as [String: String])
            .validate().responseJSON { (response) in
                
                guard response.result.isSuccess else {
                    self.tabBarController?.view.makeToast(message: Message.apiError)
                    self.fetchOfflineData()
                    return
                }
                
                let resposeJSON = response.result.value as? NSArray ?? NSArray()
                for responseJ in resposeJSON {
                    let item = responseJ as! NSDictionary
                    let model = SongModel(song_id: item["song_id"] as? String ?? "", song_name: item["song_name"] as? String ?? "", image: item["image"] as? String ?? "", path: item["song_path"] as? String ?? "", filetype: item["filetype"] as? String ?? "", filesize: item["filesize"] as? String ?? "", duration: item["duration"] as? String ?? "", artist_name: item["artist_name"] as? String ?? "", artistImage: item["artist_image"] as? String ?? "", price: "")
                    if URL(string: item["song_path"] as? String ?? "") != nil{
                        self.reDownloadArray.append(model)
                    }else{
                        print("Not a downloadable url")
                    }
                }
                self.fetchOfflineData()
            }
    }

    fileprivate func fetchOfflineData(){
        offlineDataArray = ContentDetailsEntity.fetchData().map { (currentData) -> ContentDetailsEntityModel in
            var currentDownloadData = currentData
            currentDownloadData.songImage = DownloadDirectory.images?.appendingPathComponent(currentData.songImage).path ?? ""
            currentDownloadData.artistImage = DownloadDirectory.images?.appendingPathComponent(currentData.artistImage).path ?? ""
            currentDownloadData.songPath = DownloadDirectory.audios?.appendingPathComponent(currentData.songPath).path ?? ""
            currentDownloadData.fileSize = ByteCountFormatter.string(fromByteCount: Int64(currentData.fileSize) ?? 0, countStyle: .file)
            return currentDownloadData
        }
        var newReDownloadArray = [SongModel]()
        for d in reDownloadArray{
            let newOne = offlineDataArray.filter({$0.songID == d.song_id}).count > 0
            if !newOne{
                newReDownloadArray.append(d)
            }
        }
        reDownloadArray = newReDownloadArray
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.tableView.reloadData()
        }
        
        if offlineDataArray.count == 0 && reDownloadArray.count == 0{
            self.navigationItem.rightBarButtonItems = []
            let alertController = UIAlertController(title: "Alert!", message: "No songs found in offline or redownload section.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }else if offlineDataArray.count == 0{
            self.navigationItem.rightBarButtonItems = [downloadAllButton]
        } else if reDownloadArray.count == 0{
            self.navigationItem.rightBarButtonItems = [playAllButton]
        }else{
            self.navigationItem.rightBarButtonItems = [playAllButton, downloadAllButton]
        }
    }

    func downloadAudio(data: SongModel){
        var contentData =  ContentDetailsEntityModel()
        contentData.artistImage = data.artistImage
        contentData.artistName = data.artist_name
        contentData.songName = data.song_name
        contentData.songID = data.song_id
        contentData.songImage = data.image
        contentData.songPath = data.path
        contentData.fileSize = data.filesize
        contentData.fileType = data.filetype
        contentData.songDuration = data.duration.durationString
        TonneruDownloadManager.shared.delegate = self
        TonneruDownloadManager.shared.isDownloadNotification = false
        TonneruDownloadManager.shared.addDownloadTask(data: contentData)
    }

    @objc fileprivate func deleteAction(sender: UIButton){
        if TonneruMusicPlayer.shared.songList.count > 0 && TonneruMusicPlayer.shared.currentIndex > -1 && TonneruMusicPlayer.shared.songList.count > TonneruMusicPlayer.shared.currentIndex{
            let currentPlayingSongID = TonneruMusicPlayer.shared.songList[TonneruMusicPlayer.shared.currentIndex].song_id
            if self.offlineDataArray[sender.tag].songID == currentPlayingSongID && TonneruMusicPlayer.shared.isMiniViewActive {
                self.showAlert(message: "You can not delete the song as it is playing now.")
                return
            }
        }
        
        let alertController = UIAlertController(title: "Alert!", message: "Are you sure you want to delete the downloaded song?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
            let currentDownloadData = self.offlineDataArray[sender.tag].songID
            self.deleteSongFromServer(songId: currentDownloadData)
        }
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteSongFromServer(songId: String){
        Alamofire.request(URL(string: "https://tonnerumusic.com/api/v1/removesongfromdownloads")!,
                          method: .post,
                          parameters: [
                            "user_id": UserDefaults.standard.fetchData(forKey: .userId),
                            "song_id": songId
                          ] as [String: String])
            .validate().responseJSON { (response) in
                guard response.result.isSuccess else {
                    self.tabBarController?.view.makeToast(message: Message.apiError)
                    return
                }
                let resposeJSON = response.value as? NSDictionary ?? NSDictionary()
                if resposeJSON["status"] as? Bool == true{
                    ContentDetailsEntity.delete(songId: songId)
                    self.fetchOfflineData()
                }
                self.tabBarController?.view.makeToast(message: resposeJSON["message"] as! String)
            }
    }

    fileprivate func resetPlayer(){
        TonneruMusicPlayer.shared.currentIndex = -1
        TonneruMusicPlayer.shared.songList.removeAll()
        TonneruMusicPlayer.repeatMode = .off
        TonneruMusicPlayer.shuffleModeOn = false
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 88))
    }
    
    func tapAction(state: DownloadButtonStatus, sender: TonneruDownloadButton) {
        print("Download Button State: \(state)")
        activityIndicator.startAnimating()
        downloadAudio(data: reDownloadArray[sender.tag])
    }
}

extension MyDownloadViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let l = UILabel()
        l.textColor = ThemeColor.headerColor
        if section == 0 {
            l.text = "OFFLINE"
        }else{
            l.text = "RE-DOWNLOAD"
        }
        return l
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            if offlineDataArray.count > 0{
                return 20
            }else{
                return 0
            }
        }else if section == 1{
            if reDownloadArray.count > 0{
                return 20
            }else{
                return 0
            }
        } else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? offlineDataArray.count : reDownloadArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadTableViewCell", for: indexPath) as! DownloadTableViewCell
            cell.backgroundColor = .clear
            cell.data = offlineDataArray[indexPath.row]
            cell.deleteButton.tag = indexPath.row
            cell.deleteButton.addTarget(self, action: #selector(self.deleteAction(sender:)), for: .touchUpInside)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongInPlayListTVCell", for: indexPath) as! SongInPlayListTVCell
            cell.backgroundColor = .clear
            cell.downloadButton.delegate = self
            cell.downloadButton.downloadCompleteImage = UIImage(named: "downloadComplete")
            cell.downloadButton.tintColor = ThemeColor.buttonColor
            cell.downloadButton.tag = indexPath.row
        
            let objAlbum = reDownloadArray[indexPath.row]
            cell.lblTitle.text = objAlbum.song_name
            cell.lblDescription.text = objAlbum.artist_name
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 100 : 65
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            resetPlayer()
            TonneruMusicPlayer.shared.initialize()
            let songData = SongModel(song_id: offlineDataArray[indexPath.row].songID, song_name: offlineDataArray[indexPath.row].songName, image: offlineDataArray[indexPath.row].songImage, path: offlineDataArray[indexPath.row].songPath, filetype: offlineDataArray[indexPath.row].fileType, filesize: offlineDataArray[indexPath.row].fileSize, duration: offlineDataArray[indexPath.row].songDuration, artist_name: offlineDataArray[indexPath.row].artistName, artistImage: offlineDataArray[indexPath.row].artistImage)
            TonneruMusicPlayer.shared.playSong(data: [songData], index: 0)
        }else{
            showAlert(message: "You have to download first this song")
        }
    }
}
extension MyDownloadViewController : TonneruDownloadManagerDelegate{
    func tonneruDownloadManager(progress: Float, content: CurrentDownloadEntityModel) {
        if isDownloadEnable{
            if progress == 1.0{
                downloadSongCounter = downloadSongCounter + 1
                print("downloadSongCounter:\(downloadSongCounter)")
                if downloadSongCounter == newSongCounter {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.fetchOfflineData()
                        self.isDownloadEnable = false
                    })
                }
            }
        }else{
            if progress == 1.0{
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.activityIndicator.stopAnimating()
                    self.fetchOfflineData()
                })
            }
        }
    }
}
