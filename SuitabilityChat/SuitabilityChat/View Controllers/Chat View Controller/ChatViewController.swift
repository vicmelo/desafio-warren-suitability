//
//  ChatViewController.swift
//  SuitabilityChat
//
//  Created by Victor S Melo on 06/03/18.
//  Copyright © 2018 Victor Melo. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {
    
    // MARK: - Properties
    
    var chatStackView: UIStackView!
    var chatScrollView: UIScrollView!

    var userInputViewContainer: UIView!
    var textUserInputView: TextUserInputView!
    var buttonsUserInputView: ButtonsUserInputView!
    
    var bottomConstraint: NSLayoutConstraint?
    var inputContainerHeight: NSLayoutConstraint?
    
    var messagesManager: MessagesDisplayManager!
    
    // MARK: - Init & Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        messagesManager = MessagesDisplayManager(delegate: self)

        setupView()
        
        ChatManager.shared.startChat {
            if $0.inputs.count > 0 {
                self.messagesManager.sendMessages($0.messagesAsActions, expectedAnswer: .text(apiInputs: $0.inputs))
            } else if $0.buttons.count > 0 {
                self.messagesManager.sendMessages($0.messagesAsActions, expectedAnswer: .buttons($0.buttons))
            } else {
                
                self.messagesManager.sendMessages($0.messagesAsActions, expectedAnswer: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chatScrollView.contentSize = CGSize(width: chatStackView.frame.width, height: chatStackView.frame.height)
        
    }

    // MARK: - View Setups
    
    private func setupView() {
        setupUserInputViews()
        setupScrollView()
        setupStackView()
    }
    
    private func setupUserInputViews() {
        setupUserInputViewContainer()
        setupTextUserInputView()
        setupButtonsUserInputView()

    }
    
    private func setupScrollView() {
        chatScrollView = UIScrollView(frame: self.view.frame)
        chatScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatScrollView)
        
        //constraints
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView": chatScrollView]))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView][userInputViewContainer]", options: .alignAllCenterX, metrics: nil, views: ["scrollView": chatScrollView, "userInputViewContainer": userInputViewContainer]))
    }
    
    private func setupStackView() {
        
        chatStackView = UIStackView(frame: self.view.frame)
        chatStackView.translatesAutoresizingMaskIntoConstraints = false
        chatStackView.axis = .vertical
        chatStackView.spacing = 20
        chatScrollView.addSubview(chatStackView)
        
        // constraints
        
        chatScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stackView]|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": chatStackView]))
        chatScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stackView]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": chatStackView]))
    }
    
    private func setupUserInputViewContainer() {
        userInputViewContainer = UIView()
        
        view.addSubview(userInputViewContainer)
        
        userInputViewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        inputContainerHeight = userInputViewContainer.heightAnchor.constraint(equalToConstant: 0.0)
        
        bottomConstraint = NSLayoutConstraint(item: userInputViewContainer, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[userInputViewContainer]|", options: .alignAllCenterX, metrics: nil, views: ["userInputViewContainer": userInputViewContainer]))

    }
    
    private func setupTextUserInputView() {
        textUserInputView = TextUserInputView()
        textUserInputView.delegate = self
        
        userInputViewContainer.addSubview(textUserInputView)
        
        textUserInputView.translatesAutoresizingMaskIntoConstraints = false
        
        // constraints
        
        userInputViewContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textUserInputView]|", options: .alignAllCenterX, metrics: nil, views: ["textUserInputView": textUserInputView]))
        userInputViewContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[textUserInputView]|", options: .alignAllCenterX, metrics: nil, views: ["textUserInputView": textUserInputView]))
        
    }
    
    private func setupButtonsUserInputView() {
        buttonsUserInputView = ButtonsUserInputView()
        buttonsUserInputView.delegate = self
        
        userInputViewContainer.addSubview(buttonsUserInputView)
        
        buttonsUserInputView.translatesAutoresizingMaskIntoConstraints = false
        
        // constraints
        
        userInputViewContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[buttonsUserInputView]|", options: .alignAllCenterX, metrics: nil, views: ["buttonsUserInputView": buttonsUserInputView]))
        userInputViewContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[buttonsUserInputView]|", options: .alignAllCenterX, metrics: nil, views: ["buttonsUserInputView": buttonsUserInputView]))

    }
    
    // MARK: - Keyboard handling

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        guard let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardSize = keyboardInfo.cgRectValue.size
        adjustBottomConstraint(constant: -keyboardSize.height)
        
        showLastMessage()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
    }
    
    /// Adjust the scrollView bottom constraint to the parameter constant.
    private func adjustBottomConstraint(constant: CGFloat) {
        
        bottomConstraint?.constant = constant
        
        UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (_) in
                
        })
        
    }
    
    // MARK: -

    /// Will show to the user the last message added. If it's already being showed, does nothing.
    private func showLastMessage() {
        if chatScrollView.contentSize.height > chatScrollView.bounds.size.height {
            let bottomOffset = CGPoint(x: 0, y: chatScrollView.contentSize.height - chatScrollView.bounds.size.height)
            chatScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    /// Returns the current user answer formatted according to userResponses received from API.
    private func getUserAnswerFormatted(answer: String) -> String {
        
//        let response = ChatManager.shared.userResponses.first!
//
//        let reversedResponse = "\(response.reversed())"
//        guard let startingIndex = response.index(of: "{"), let endingIndex = reversedResponse.index(of: "}") else {
//            return "Message"
//        }
//
        return answer
        //        let inputPart = "\(userResponse[startingIndex ... endingIndex])"
        
        // separar os "subelementos" (ex: {answers.question_name})
        
        // para cada "subelemento", mapear o valor já informado dele (ex: no caso acima, precisa pegar o nome do usuário)
        
        // injetar o valor real de cada "subelemento" no local devido
        
        // retornar string
        
    }
}

extension ChatViewController: UserInputViewDelegate {
    
    func userDidAnswer(value: String, answer: String) {
    
        // hide keyboard
        view.endEditing(true)
        
        //add user message bubble
        let userMsg = UserMessageView(text: getUserAnswerFormatted(answer: answer), responseFormatting: nil, font: UIFont.systemFont(ofSize: 16))
        self.chatStackView.addArrangedSubview(userMsg)
        
        adjustBottomConstraint(constant: userInputViewContainer.frame.height)
        
        ChatManager.shared.addAnswer(userAnswer: value)
        
        ChatManager.shared.getResponse { apiResponse in

            if apiResponse.inputs.count > 0 {
                self.messagesManager.sendMessages(apiResponse.messagesAsActions, expectedAnswer: .text(apiInputs: apiResponse.inputs))
            } else if apiResponse.buttons.count > 0 {
                self.messagesManager.sendMessages(apiResponse.messagesAsActions, expectedAnswer: .buttons(apiResponse.buttons))
            } else {
                self.messagesManager.sendMessages(apiResponse.messagesAsActions, expectedAnswer: nil)
            }
        }
    }
}

extension ChatViewController: MessagesDisplayManagerDelegate {
    
    func addMessageToView(_ messageView: UIView) {
        guard let msgBot = messageView as? BotMessageView else {
            print("[ChatViewController] Couldn't get BotMessageView")
            return
        }
        
        self.chatStackView.addArrangedSubview(msgBot)
        
        // adjust chatScrollView content size to show the last message while it is being typed
        let lastMessageHeightOffset = msgBot.frame.height + chatStackView.spacing*2
        if (chatScrollView.contentSize.height + lastMessageHeightOffset) > chatScrollView.bounds.size.height {
            chatScrollView.contentSize = CGSize(width: chatStackView.frame.width, height: chatStackView.frame.height + lastMessageHeightOffset)
        }
        
        showLastMessage()
    }
    
    func needToGetAnswer(_ inputType: InputType) {
        switch inputType {
        case .text(let inputs):
            textUserInputView.present(textFieldHeight: 50.0, inputs: inputs)
            adjustBottomConstraint(constant: 0)
            
        case .buttons(let buttons):
            buttonsUserInputView.present(buttonHeight: 50.0, buttons: buttons)
            adjustBottomConstraint(constant: 0)
            
        }
        
        showLastMessage()
    }
    
}
