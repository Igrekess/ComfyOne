# ComfyOne - Capture One Integration with ComfyUI API

This script, **ComfyOne**, integrates the **ComfyUI API** directly within **Capture One**, offering extensive control over AI-powered image generation through a highly customizable interface. **ComfyOne** provides control over prompts, workflows, resolution, dual ControlNet support, IP-Adapter, and inpainting settings—all managed within Capture One. 

**Work In Progress**

## Key Features

- **Server Configuration**: Easily connect to the ComfyUI server by specifying its URL, with a default of `127.0.0.1:8188`.
- **Workflow Management**: Dynamically loads available workflows from a specified folder, allowing users to select and execute a workflow from within Capture One.
- **Prompting System**: Define positive and negative prompts to guide content in the generated image and set seed values to control randomness.
- **Resolution and Denoising**: Choose from predefined resolution settings (Low, Mid, High) and set denoising levels to refine image clarity.
- **Masking Options**: Configure mask prompts to target specific areas of the image with options for blur, expand, invert, or fill.
- **Dual ControlNet Integration**: Supports two ControlNets (ControlNet A and B) simultaneously, each with customizable parameters and custom reference images.
- **IP-Adapter Functionality**: Customize the IP-Adapter for stylistic refinement with separate reference images.
- **Inpainting Mode**: Inpainting settings enable targeted editing with blur and blending options for masks.

## Node Naming and Automated Workflow Management

To fully automate workflow management through **ComfyOne**, users need to follow a naming convention for nodes within the JSON workflow. By adhering to the **ComfyUI API JSON** structure, a separate Python script can dynamically manage parameters based on these identifiers.

### Node Identifiers for Automation

- **Prompt Control**:
  - `PositivePromptAPI`
  - `NegativePromptAPI`
- **Image Generation**:
  - `SeedAPI`
  - `DenoiseAPI`
  - `SrcImgAPI`
  - `SaveImgAPI`
- **Advanced Settings**:
  - `turboOnAPI`
  - `inpaintOnAPI`
  - `resolutionAPI`
- **Masking and Inpainting**:
  - `maskAPI`
  - `inpaintAPI`
- **ControlNet Nodes**:
  - `ctrlNetAAPI`
  - `ctrlNetBAPI`
  - `uploadImgCtrlNetA`
  - `uploadImgCtrlNetB`
- **IP-Adapter Node**:
  - `ipAdapterAPI`
  - `uploadImgipAdapter`

## Workflow Tree with Adjustable Variables per Node

- **PositivePromptAPI**: Adjust the positive prompt for image generation.
- **NegativePromptAPI**: Adjust the negative prompt to filter out unwanted elements.
- **SeedAPI**: Set the seed value to control randomness.
- **DenoiseAPI**: Adjust the denoising level.
- **SrcImgAPI**: Source image input path.
- **SaveImgAPI**: Output image save path.
- **turboOnAPI**: Boolean for Turbo mode.
- **inpaintOnAPI**: Boolean for inpainting mode.
- **resolutionAPI**: Set the resolution (Low, Mid, High).
- **maskAPI**: Configure mask settings.
- **inpaintAPI**: Control blur and blend for inpainting.
- **ctrlNetAAPI / ctrlNetBAPI**: ControlNet A and B settings.
- **uploadImgCtrlNetA / uploadImgCtrlNetB**: Upload custom images for ControlNet.
- **ipAdapterAPI**: IP-Adapter settings.
- **uploadImgipAdapter**: Reference image upload for IP-Adapter.

## Script Execution and Generation from Capture One

A secondary script enables **direct image generation from the Capture One window** using saved parameters, allowing quick iterations without reconfiguring settings.

## Installation Script

**ComfyOne** includes an installation script that sets up a **virtual environment (venv)** and installs necessary libraries, ensuring proper configuration.

## User Interface and Configuration

Using [**AppleScript’s Dialog Toolkit Plus**](https://s3.amazonaws.com/latenightsw.com/ShaneLibs/Dialog_Toolkit.zip) and [**PrefsStorageLib**](https://s3.amazonaws.com/latenightsw.com/ShaneLibs/PrefsStorageLib_stuff.zip), this script provides a user-friendly interface within Capture One for managing inputs and saving preferences.

## Workflow Execution

Once configured, users can run the script to:
- Apply chosen parameters to the diffusion model on the ComfyUI server.
- Save configurations for repeatability.

**ComfyOne** empowers professionals in image generation with ControlNet for compositional guidance, IP-Adapter for styling, and complete node-based automation using the **ComfyUI API JSON** format.
