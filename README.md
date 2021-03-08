# canvas-cli
A Bash CLI for the Canvas VLE  
*Note: Canvas CLI is a third-party script and has no official affiliation with Canvas*  

## Installation
Canvas CLI is a bash script, so you can just clone it somewhere and make sure it's added to your `$PATH`.  
For example:
    $ git clone "https://github.com/joe-herbert/canvas-cli.git" /usr/local/bin/canvas-cli  
    $ chmod +x /usr/local/bin/canvas-cli/canvas.sh  

## Usage
    Usage:  
        canvas <operation> -h           Display help for specific operation.  
        canvas <operation> [option]     Execute one of the operations below.  
    Operations:  
        h help      Display this help message.  
        u upcoming  Display any assignments which are due in the future.  
        g grades    Display submitted assignments and grades.  
        s settings  Change your canvas url or token.  

### Generating a Canvas Token
You must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name "Canvas CLI" and with no expiration date. Copy the token value and run `canvas s`. Enter the url you access Canvas at (e.g. liverpool.instructure.com) and then paste the token when requested.  

## Bugs/Contributing
If you find any bugs then please report it here on GitHub or by dropping me an email at <joe@joeherbert.dev>.  
If you want to contribute then feel free! Just make any changes and create a PR.  

## License
GNU General Public License v3.0
