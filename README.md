# mock-spacestation

## What is mock-spacestation?

mock-spacestation empowers developers and enthusiasts to develop and test their own space-based applications with similar constraints from projects deployed to the International Space Station (ISS).  Leveraging [Bicep template](https://aka.ms/bicep) and/or [Dev Containers](https://code.visualstudio.com/docs/remote/create-dev-container), it deploys consists of a mock Groundstation (a virtual machine) and a mock Spacestation (a container) with similar network latency, deployment, authentication, and configurations from other ISS projects.  

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbigtallcampbell%2Fmock-spacestation%2Fmain%2FmockSpacestation.json)

This template was leveraged by the Azure Space team during the development of the genomics experiment while preparing for installation of the Hewlett Packard Enterprise (HPE) Spaceborne Computer 2 (SBC2) aboard the ISS.  

For context, here's a video summary of that experiment executed in August of 2021:
[![Video overview of the Azure and HPE Genomics experiment on the International Space Station](http://img.youtube.com/vi/wZfIUkcgVxI/0.jpg)](https://www.youtube.com/watch?v=wZfIUkcgVxI "Genomics testing on the ISS with HPE Spaceborne Computer-2 and Azure")





## What it simulates

1. **Latency**

    ~400ms latency between the mock ground station and the mock space station to simulate the internation hops and routing leveraged by the ISS
    

1. **Bandwidth**

    2Mb/s to match the actual bandwidth cap when communicating with the ISS.  No internet connectivity from the Space Station

1. **Synchronization**

    Two directories: 
    - "Ground Station" ($env:USERPROFILE\\.mockspacestation\groundstation) "pushes" from the ground to the space station 
    - "Space Station" ($env:USERPROFILE\\.mockspacestation\spacestation) "pushes" from the space station to the ground
    

1. **Processing at The Edge and "Bursting Down" to The Cloud**

    The Azure Space team used computing power of the HPE SBC2 on-board the ISS to perform intensive work for their genomics experiment, allowing them to identify and transmit the critical information to Earth through the narrow 2 megabit per second pipe, where it was further processed on a global scale with Azure.

# Get started with mock-spacestation

*Needs updated with new BICEP script*

# Developers - deploy template in VSCode
1. Verify you have [VSCode](https://code.visualstudio.com/Download), [Docker Community](https://hub.docker.com/editions/community/docker-ce-desktop-windows), and [Remote Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Install [WSL2 (Windows-Subsystem-Linux v2)](https://docs.microsoft.com/en-us/windows/wsl/install) and set V2 as default
````powershell
wsl --set-default-version 2
````
3. [Update Docker to use WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers#:~:text=1%20Download%20Docker%20Desktop%20and%20follow%20the%20installation,simple%20built-in%20Docker%20image%20using%3A%20docker%20run%20hello-world)
4. Open the template and let magic happen<br><br>


# Connect to mock Space Station
