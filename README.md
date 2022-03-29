# ICBuildTools

## Use this ASP.NET Web page to run any executable file installed on a server or remote machine).
- Looks great thanks to Bootstrap 5
- Easy to use

## Instructions
- Fork/Clone this repository like this:
- CMD> MKDIR ICBT
- CMD> CD ICBT
- CMD> git clone https://github.com/RlyehDoom/ICBuildTools.git .
- Now on IIS create a web site and use this folder as the physical path.
- Run the web site using you own credentials (APP pool with credentials).
- Set the website Authentication to Windows only and disable anonymous.
- Done!

### Just create a web site that support ASP.NET C# (Framework 4.0 or greater) and put this files in your main directory.


- Feel free to ask for any advice or participation.
- Important: Change the web.config file AppKeys to match your own setup.

## IMPORTANT: This is basically an example proyect of how to run executable files in a remote server/machine (the permissions should be granted by the Web pool running your web site).

#Example Run Daemons
#### You should access this webpage in some location for example: http://myserver/AnyFolderName/DaemonExecutor.aspx
![Alt text](https://user-images.githubusercontent.com/1031037/157799893-f0901e9f-9d22-4b45-b858-6e1f84b658f0.png)

#Example NETExecutor
#### You should access this webpage in some location for example: http://myserver/AnyFolderName/NETExecutor.aspx
![Alt text](https://user-images.githubusercontent.com/1031037/160464134-d405cc0a-f543-4ce8-8ec1-997952b441be.png)
