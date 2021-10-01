# Mock-Spacestation
## What is Mock-Spacestation?

Mock-Spacestation empowers developers and enthusiasts to create their own space-based applications with similar constraints from projects deployed to the International Space Station (ISS).  Leveraging [Bicep template](https://aka.ms/bicep) or [Dev Containers](https://code.visualstudio.com/docs/remote/create-dev-container), it deploys a mock Groundstation (host virtual machine/container) and a mock Spacestation (a container) with similar network latency, deployment, authentication, and configurations from other ISS projects.  


This template was leveraged by the Azure Space team during the development of the genomics experiment while preparing for installation of the Hewlett Packard Enterprise (HPE) Spaceborne Computer 2 (SBC2) aboard the ISS.  

For context, here's a video summary of that experiment executed in August of 2021:
[![Video overview of the Azure and HPE Genomics experiment on the International Space Station](http://img.youtube.com/vi/wZfIUkcgVxI/0.jpg)](https://www.youtube.com/watch?v=wZfIUkcgVxI "Genomics testing on the ISS with HPE Spaceborne Computer-2 and Azure")


# Quick Start to Azure
1. [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbigtallcampbell%2Fmock-spacestation%2Fmain%2FAzureVM.json)
1. SSH into new Ground Station VM (check Output from Template for quick copy/paste SSH command)
    <br> **Note**: The post provisioning process takes ~5 mins to complete.  Once you SSH, you can check the progress by 
    `cat ./mockspacestation-provisioning.log` <br>
    Looking for *Mock Space Station Configuration (v2.0) Complete*
1. You are now connected to **GroundStation**! 
    1. `ls .` to see directories <br>
    ![ls .](/docs/images/groundStationLS.png)
    1. When connected to **GroundStation**:
        - Send files to **spacestation** by placing in `./groundstation`    
        - Files sent by **spacestation** are in `./spacestation`
1. SSH into spacestation by `./ssh-to-spacestation.sh`<br>
    ![ls .](/docs/images/sshFromGroundStation.png) <br>
    When connected to spacestation:<br>
    - Send files to **groundstation** by placing in `./spacestation`
    - Files sent by **groundstation** are in `./groundstation`
    - See Containers running by `docker images`

# Quick Start for local development
1. Clone this repo
1. Verify you have [VSCode](https://code.visualstudio.com/Download), [Docker Community](https://hub.docker.com/editions/community/docker-ce-desktop-windows), and [Remote Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
1. Install [WSL2 (Windows-Subsystem-Linux v2)](https://docs.microsoft.com/en-us/windows/wsl/install) and set V2 as default
    ````powershell
    wsl --set-default-version 2
    ````
1. [Update Docker to use WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers#:~:text=1%20Download%20Docker%20Desktop%20and%20follow%20the%20installation,simple%20built-in%20Docker%20image%20using%3A%20docker%20run%20hello-world)
1. Open the template and wait for provisionsing
1. Follow *Quick Start to Azure* "You are now connected to **GroundStation**!"


## What it simulates   
1. **Processing at The Edge and "Bursting Down" to The Cloud**
    The Azure Space team used computing power of the HPE SBC2 on-board the ISS to perform intensive work for their genomics experiment, allowing them to identify and transmit the critical information to Earth through the narrow 2 megabit per second pipe, where it was further processed on a global scale with Azure.

1. **Latency**
    ~400ms latency between the mock ground station and the mock space station to simulate the internation hops and routing leveraged by the ISS  
1. **Bandwidth**
    2Mb/s to match the actual bandwidth cap when communicating with the ISS.  No internet connectivity from the Space Station
1. **Synchronization**
    Two directories: 
    - `./groundstation` is for Ground Station to send files to Space Station 
    - `./spacestation` is for Space Station to send files to Ground Station<br>
    Both synchronizations are limited by the above bandwidth and latency constraints.  Synchronization runs every 60 secs.
1. **Connectivity**
    No connectivity between Space Station and Internet.<br>
    *Note:* Ground-to-ISS connectivity is approximately 2hrs / week.  This is **not** simulated to assist with development, but should be a consideration in the final deployment

## Develop an app
1. Create your app, or try the [dotnetapp Sample App](https://github.com/dotnet/dotnet-docker/tree/main/samples/dotnetapp):<br>
    `docker build --pull -t dotnetapp .`
    <br>*Note: we'll assume you used the dotnetapp sample.  Update the image name/tags to match your app*
1. Save your docker image to the local file store via `docker save --output C:\Temp\dotnetsample-img.tar dotnetsample:latest`
1. Create a file `load-and-start.sh` in `C:\Temp\`<br>
    ````bash
    #!/usr/bin/env bash
    docker load --input ./dotnetsample-img.tar
    docker run -d dotnetsample:latest --volume=/home/azureuser/spacestation:/spacestation Hello .NET from Space Station
    #plus any environment variables, relative mounting paths for input/output, etc.
    ````
1. Anything your app writes to `./spacestation` will be replicated to the ground


# An Example "Burst Down" Workload

The Azure Space team's genomics experiment is an example of a solution you could build with these mock-spacestation components:

![The Azure Space and HPE Spaceborne Computer 2 Genmoics Experiment Architecture](docs/images/azure-space-genomics-experiment-architecture.png)]

More technical information on the experiment can be found at this blog post: [https://azure.microsoft.com/en-us/blog/genomics-testing-on-the-iss-with-hpe-spaceborne-computer2-and-azure/](https://azure.microsoft.com/en-us/blog/genomics-testing-on-the-iss-with-hpe-spaceborne-computer2-and-azure/)

### On the Spacestation

- A Linux container hosts a Python workload, which is packaged with data representing mutated DNA fragments and wild-type (meaning normal or non-mutated) human DNA segments. There are 80 lines of Python code, with a 30-line bash script to execute the experiment.

- The Python workload generates a configurable amount of DNA sequences (mimicking gene sequencer reads, about 70 nucleotides long) from the mutated DNA fragment.

- The Python workload uses awk and grep to compare generated reads against the wild-type human genome segments.

- If a perfect match cannot be found for a read, it’s assumed to be a potential mutation and is compressed into an output folder on the Spaceborne Computer-2 network-attached storage device.
After the Python workload completes, the compressed output folder is sent to the HPE ground station on Earth via rsync.

### On Earth

- The HPE ground station uploads the data it receives to Azure, writing it to Azure Blob Storage through azcopy.

- An event-driven, serverless function written in Python and hosted in Azure Functions monitors Blob Storage, retrieving newly received data and sending it to the Microsoft Genomics service via its REST API.

- The Microsoft Genomics service, hosted on Azure, invokes a gene sequencing pipeline to “align” each read and determine where, how well, and how unambiguously it matches the full reference human genome. (The Microsoft Genomics service is a cloud implementation of the open-source Burroughs-Wheeler Aligner and Genome Analysis Toolkit, which Microsoft tuned for the cloud.)

- Aligned reads are written back to Blob Storage in Variant Call Format (VCF), a standard for describing variations from a reference genome.

- A second serverless function hosted in Azure Functions retrieves the VCF records, using the determined location of each mutation to query the dbSNP database hosted by the National Institute of Health—as needed to determine the clinical significance of the mutation—and writes that information to a JSON file in Blob Storage.

- Power BI retrieves the data containing clinical significance of the mutated genes from Blob Storage and displays it in an easily explorable format.
