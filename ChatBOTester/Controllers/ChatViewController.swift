//
//  ChatViewController.swift
//  ChatBOTester
//
//  Created by GLB-312-PC on 06/03/18.
//  Copyright © 2018 GLB-312-PC. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ApiAI
import AVFoundation
import AVKit
import MobileCoreServices

class ChatViewController:JSQMessagesViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    
    let speechSynthesizer = AVSpeechSynthesizer()
    let picker = UIImagePickerController()
    var senderuid = "shakti099"
    private var messages = [JSQMessage]();
    override func viewDidLoad() {
        super.viewDidLoad()
         picker.delegate = self
    }


    
    override func senderId() -> String {
        return "13456"
    }
    override func senderDisplayName() -> String {
        return "shaktiios"
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // collection view function
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: (IndexPath!)) -> JSQMessageAvatarImageDataSource? {
        
        let  message = messages[indexPath.item]
        if message.senderId == self.senderId(){
        
            return JSQMessagesAvatarImageFactory().avatarImage(with: UIImage(named: "mypic")!)
        }
        else{
             return JSQMessagesAvatarImageFactory().avatarImage(with: UIImage(named: "p")!)
        }
    }
    
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource? {
        
        let bubblefactry = JSQMessagesBubbleImageFactory()
        let message = messages[indexPath.item]
        if message.senderId == self.senderId(){
            return bubblefactry.outgoingMessagesBubbleImage(with: UIColor.cyan)
        }
        else{
            return bubblefactry.incomingMessagesBubbleImage(with: UIColor.green)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Please select A media", message: " ", preferredStyle: .actionSheet);
        let cancle = UIAlertAction(title: "Cancle", style: .cancel, handler: nil);
        let photos = UIAlertAction(title: "Photos", style: .default) { (alert: UIAlertAction) in
            self.choosemedia(type: kUTTypeImage)
        }
        let video = UIAlertAction(title: "Videos", style: .default) { (alert: UIAlertAction) in
            self.choosemedia(type: kUTTypeMovie)
        }
        alert.addAction(cancle)
        alert.addAction(photos)
        alert.addAction(video)
        present(alert, animated: true, completion: nil)
        
        
    }
    
    private func choosemedia(type : CFString){
        picker.mediaTypes = [type as String]
        present(picker, animated: true, completion: nil)
        
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
        
    }
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        collectionView?.reloadData()
        self.finishSendingMessage()
        scrollToBottom(animated: true)
        self.generatetheDesiredResponseandsynthesize(text: text)
    }
    
    func generatetheDesiredResponseandsynthesize(text: String){
        
        let request = ApiAI.shared().textRequest()
        
        if text.count > 0 {
            request?.query = text
        }
        else {
            return
        }
        
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if let textResponse = response.result.fulfillment.speech {
                self.speechAndText(text: textResponse)
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        ApiAI.shared().enqueue(request)
    }
    
    func speechAndText(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechSynthesizer.speak(speechUtterance)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut, animations: {
            self.messages.append(JSQMessage(senderId: "lotonid", displayName: "loton", text: text))
            self.collectionView?.reloadData()
            self.scrollToBottom(animated: true)
        }, completion: nil)
       
    }
    
    //MARK: Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pic = info[UIImagePickerControllerOriginalImage] as? UIImage{
            let image = JSQPhotoMediaItem(image: pic)
            self.messages.append(JSQMessage(senderId: self.senderId(), displayName: self.senderDisplayName(), media: image))
        }
        else if let  videourl = info[UIImagePickerControllerMediaURL] as? URL {
            let video = JSQVideoMediaItem(fileURL: videourl, isReadyToPlay: true, thumbnailImage: nil)
          self.messages.append(JSQMessage(senderId: self.senderId(), displayName: self.senderDisplayName(), media: video))
        }
        
        self.dismiss(animated: true, completion: nil)
        self.collectionView?.reloadData()
        
    }
    

    override func collectionView(_ collectionView: (JSQMessagesCollectionView!), didTapMessageBubbleAt indexPath: IndexPath) {
        
        let msg = messages[indexPath.item]
        
        if msg.isMediaMessage{
            
            if let  mediaItem = msg.media as? JSQVideoMediaItem {
                
                let player = AVPlayer(url: mediaItem.fileURL!)
                let playercontroller = AVPlayerViewController()
                playercontroller.player = player
                self.present(playercontroller, animated: true, completion: nil)
            }
        }
    }
    // for displaying user name
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: (IndexPath!)) -> NSAttributedString?
    {
        return messages[indexPath.item].senderId == self.senderId() ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat
    {
        return messages[indexPath.item].senderId == self.senderId() ? 0 : 15
    }
 

}
