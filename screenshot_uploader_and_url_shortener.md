

```json
{
  "Version": "14.1.0",
  "Name": "hudl.ink image service",
  "DestinationType": "URLShortener",
  "RequestMethod": "POST",
  "RequestURL": "https://hudl.ink/api/screen/upload",
  "Body": "MultipartFormData",
  "Arguments": {
    "image_title": "{filename}"
  },
  "FileFormName": "form",
  "URL": "{responseurl}"
}
```

```json
{
  "Version": "14.1.0",
  "Name": "hudl.ink url shortening service",
  "DestinationType": "URLShortener",
  "RequestMethod": "POST",
  "RequestURL": "https://hudl.ink/u/shorten",
  "Parameters": {
    "url": "{input}"
  },
  "URL": "{response}"
}
```

```json
{
  "Version": "14.1.0",
  "Name": "hudl.ink file uploading service",
  "DestinationType": "FileUploader",
  "RequestMethod": "POST",
  "RequestURL": "https://hudl.ink/api/file/upload",
  "Body": "MultipartFormData",
  "Arguments": {
    "file_title": "{filename}"
  },
  "FileFormName": "form",
  "URL": "{response}"
}
```
```json
{
  "Version": "14.1.0",
  "Name": "hudl.ink text uploading service",
  "DestinationType": "TextUploader",
  "RequestMethod": "GET",
  "RequestURL": "https://hudl.ink/api/text/upload",
  "Parameters": {
    "text": "{input}"
  }
}
```