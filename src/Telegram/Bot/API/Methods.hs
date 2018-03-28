{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
module Telegram.Bot.API.Methods where


import Data.Maybe
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Network.HTTP.Client.MultipartFormData
import Data.Aeson
import Data.Proxy
import Data.Text (Text)
import GHC.Generics (Generic)
import Servant.API
import Servant.Client hiding (Response)

import Telegram.Bot.API.Internal.Utils
import Telegram.Bot.API.MakingRequests
import Telegram.Bot.API.MultipartFormData
import Telegram.Bot.API.Types

-- * Available methods

-- ** 'getMe'

type GetMe = "getMe" :> Get '[JSON] (Response User)

-- | A simple method for testing your bot's auth token.
-- Requires no parameters.
-- Returns basic information about the bot in form of a 'User' object.
getMe :: ClientM (Response User)
getMe = client (Proxy @GetMe)

-- ** 'sendMessage'

type SendMessage
  = "sendMessage" :> ReqBody '[JSON] SendMessageRequest :> Post '[JSON] (Response Message)

-- ** 'SendMessageRequest'

-- | Request parameters for 'sendMessage'.
data SendMessageRequest = SendMessageRequest
  { sendMessageChatId                :: SomeChatId -- ^ Unique identifier for the target chat or username of the target channel (in the format @\@channelusername@).
  , sendMessageText                  :: Text -- ^ Text of the message to be sent.
  , sendMessageParseMode             :: Maybe ParseMode -- ^ Send 'Markdown' or 'HTML', if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
  , sendMessageDisableWebPagePreview :: Maybe Bool -- ^ Disables link previews for links in this message.
  , sendMessageDisableNotification   :: Maybe Bool -- ^ Sends the message silently. Users will receive a notification with no sound.
  , sendMessageReplyToMessageId      :: Maybe MessageId -- ^ If the message is a reply, ID of the original message.
  , sendMessageReplyMarkup           :: Maybe SomeReplyMarkup -- ^ Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
  } deriving (Generic)

instance ToJSON   SendMessageRequest where toJSON = gtoJSON
instance FromJSON SendMessageRequest where parseJSON = gparseJSON

-- | Use this method to send text messages.
-- On success, the sent 'Message' is returned.
sendMessage :: SendMessageRequest -> ClientM (Response Message)
sendMessage = client (Proxy @SendMessage)

-- ** 'sendPhoto'

type SendPhoto 
  = "sendPhoto" :> MultipartFormDataReqBody (SendPhotoRequest FileUpload) :> Post '[JSON] (Response Message)

-- ** 'SendPhotoRequest'

-- | Request parameters for 'sendPhoto'.
data SendPhotoRequest payload = SendPhotoRequest
  { sendPhotoChatId              :: SomeChatId -- ^ Unique identifier for the target chat or username of the target channel (in the format @@channelusername@)
  , sendPhotoPhoto               :: payload -- ^ Photo to send. You can either pass a file_id as String to resend a photo that is already on the Telegram servers, or upload a new photo.
  , sendPhotoCaption             :: Maybe Text -- ^ Photo caption (may also be used when resending photos by file_id), 0-200 characters.
  , sendPhotoParseMode           :: Maybe ParseMode -- ^ Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.
  , sendPhotoDisableNotification :: Maybe Bool -- ^ Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.
  , sendPhotoReplyToMessageId    :: Maybe Int -- ^ If the message is a reply, ID of the original message
  , sendPhotoReplyMarkup         :: Maybe SomeReplyMarkup -- ^ Additional interface options. A JSON-serialized object for a custom reply keyboard, instructions to hide keyboard or to force a reply from the user.
  } 
  deriving (Generic)

instance ToMultipartFormData (SendPhotoRequest FileUpload) where
  toMultipartFormData req =
    [ utf8Part "chat_id" (chatIdToPart $ sendPhotoChatId req) ] ++
    catMaybes
    [ utf8Part "caption" <$> sendPhotoCaption req
    , utf8Part "parse_mode" . tshow <$> sendPhotoParseMode req
    , partLBS  "disable_notification" . encode <$> sendPhotoDisableNotification req
    , utf8Part "reply_to_message_id" . tshow <$> sendPhotoReplyToMessageId req
    , partLBS  "reply_markup" . encode <$> sendPhotoReplyMarkup req
    ] ++
    [ fileUploadToPart "photo" (sendPhotoPhoto req) ]

-- | Use this method to send photos. 
-- On success, the sent Message is returned.

sendPhoto :: SendPhotoRequest FileUpload -> ClientM (Response Message)
sendPhoto = client (Proxy @SendPhoto)

uploadPhotoRequest :: SomeChatId -> FileUpload -> SendPhotoRequest FileUpload
uploadPhotoRequest chatId_ photo = SendPhotoRequest chatId_ photo Nothing Nothing Nothing Nothing Nothing

-- ** 'sendAudio'

type SendAudio 
  = "sendAudio" :> MultipartFormDataReqBody (SendAudioRequest FileUpload) :> Post '[JSON] (Response Message)

-- ** 'SendAudioRequest'

-- | This object represents request for 'sendAudio'
data SendAudioRequest payload = SendAudioRequest
  { sendAudioChatId              :: SomeChatId -- ^ Unique identifier for the target chat or username of the target channel (in the format @@channelusername@)
  , sendAudioAudio               :: payload -- ^ Audio to send. You can either pass a file_id as String to resend an audio that is already on the Telegram servers, or upload a new audio file.
  , sendAudioCaption             :: Maybe Text -- ^ Audio caption, 0-200 characters
  , sendAudioParseMode           :: Maybe ParseMode -- ^ Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.
  , sendAudioDuration            :: Maybe Int -- ^ Duration of the audio in seconds
  , sendAudioPerformer           :: Maybe Text -- ^ Performer
  , sendAudioTitle               :: Maybe Text -- ^ Track name
  , sendAudioDisableNotification :: Maybe Bool -- ^ Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.
  , sendAudioReplyToMessageId    :: Maybe Int -- ^ If the message is a reply, ID of the original message
  , sendAudioReplyMarkup         :: Maybe SomeReplyMarkup -- ^ Additional interface options. A JSON-serialized object for a custom reply keyboard, instructions to hide keyboard or to force a reply from the user.
  } deriving (Generic)

instance ToMultipartFormData (SendAudioRequest FileUpload) where
  toMultipartFormData req =
    [ utf8Part "chat_id" (chatIdToPart $ sendAudioChatId req) ] ++
    catMaybes
    [ utf8Part "caption" <$> sendAudioCaption req
    , utf8Part "duration" . tshow <$> sendAudioDuration req
    , utf8Part "parse_mode" . tshow <$> sendAudioParseMode req
    , utf8Part "performer" <$> sendAudioPerformer req
    , utf8Part "title" <$> sendAudioTitle req
    , partLBS  "disable_notification" . encode <$> sendAudioDisableNotification req
    , utf8Part "reply_to_message_id" . tshow <$> sendAudioReplyToMessageId req
    , partLBS  "reply_markup" . encode <$> sendAudioReplyMarkup req
    ] ++
    [ fileUploadToPart "audio" (sendAudioAudio req) ]

-- | Use this method to send audio files, if you want Telegram clients to display them in the music player. 
-- Your audio must be in the .mp3 format. On success, the sent Message is returned. 
-- Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
sendAudio :: SendAudioRequest FileUpload -> ClientM (Response Message)
sendAudio = client (Proxy @SendAudio)

uploadAudioRequest :: SomeChatId -> FileUpload -> SendAudioRequest FileUpload
uploadAudioRequest chatId_ audio = SendAudioRequest chatId_ audio Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing


-- ** 'sendDocument'

type SendDocument 
  = "sendDocument" :> MultipartFormDataReqBody (SendDocumentRequest FileUpload) :> Post '[JSON] (Response Message)

-- ** 'SendDocumentRequest'

-- | This object represents request for 'sendDocument'
data SendDocumentRequest payload = SendDocumentRequest
  { sendDocumentChatId              :: SomeChatId -- ^ Unique identifier for the target chat or username of the target channel (in the format @@channelusername@)
  , sendDocumentDocument            :: payload -- ^ File to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data.
  , sendDocumentCaption             :: Maybe Text -- ^ Document caption, 0-200 characters
  , sendDocumentParseMode           :: Maybe ParseMode -- ^ Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.
  , sendDocumentDisableNotification :: Maybe Bool -- ^ Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.
  , sendDocumentReplyToMessageId    :: Maybe Int -- ^ If the message is a reply, ID of the original message
  , sendDocumentReplyMarkup         :: Maybe SomeReplyMarkup -- ^ Additional interface options. A JSON-serialized object for a custom reply keyboard, instructions to hide keyboard or to force a reply from the user.
  } deriving (Generic)

instance ToMultipartFormData (SendDocumentRequest FileUpload) where
  toMultipartFormData req =
    [ utf8Part "chat_id" (chatIdToPart $ sendDocumentChatId req) ] ++
    catMaybes
    [ utf8Part "caption" <$> sendDocumentCaption req
    , utf8Part "parse_mode" . tshow <$> sendDocumentParseMode req
    , partLBS  "disable_notification" . encode <$> sendDocumentDisableNotification req
    , utf8Part "reply_to_message_id" . tshow <$> sendDocumentReplyToMessageId req
    , partLBS  "reply_markup" . encode <$> sendDocumentReplyMarkup req
    ] ++
    [ fileUploadToPart "document" (sendDocumentDocument req) ]

-- | Use this method to send audio files, if you want Telegram clients to display them in the music player. 
-- Your audio must be in the .mp3 format. On success, the sent Message is returned. 
-- Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
sendDocument :: SendDocumentRequest FileUpload -> ClientM (Response Message)
sendDocument = client (Proxy @SendDocument)

uploadDocumentRequest :: SomeChatId -> FileUpload -> SendDocumentRequest FileUpload
uploadDocumentRequest chatId_ document = SendDocumentRequest chatId_ document Nothing Nothing Nothing Nothing Nothing




utf8Part :: Text -> Text -> Part
utf8Part inputName = partBS inputName . T.encodeUtf8

chatIdToPart :: SomeChatId -> Text
chatIdToPart (SomeChatId chId)    = case chId of
  ChatId integer -> tshow integer
chatIdToPart (SomeChatUsername text) = tshow text

fileUploadToPart :: Text -> FileUpload -> Part
fileUploadToPart inputName fileUpload =
  let part =
        case fileUpload_content fileUpload of
          FileUploadFile path -> partFileSource inputName path
          FileUploadBS bs     -> partBS inputName bs
          FileUploadLBS lbs   -> partLBS inputName lbs
  in part { partContentType = fileUpload_type fileUpload }

tshow :: Show a => a -> Text
tshow = T.pack . show
