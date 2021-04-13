# canvas-cli
A Bash CLI for the Canvas VLE  
*Note: Canvas CLI is a third-party script and has no official affiliation with Canvas*  

## Installation
[Canvas CLI](canvas) is a bash script, so you can just download it somewhere and make sure it's added to your `$PATH`.  
For example, this one liner:  

    $ sudo sh -c "curl https://raw.githubusercontent.com/joe-herbert/canvas-cli/main/canvas -o /usr/local/bin/canvas && chmod +x /usr/local/bin/canvas"

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
You must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name "Canvas CLI" and with no expiration date. Copy the token value and run `canvas s` in your terminal. Enter the url you access Canvas at (e.g. liverpool.instructure.com) and then paste the token when requested.  

### Upcoming Assignments
Use with one of the following commands:

    canvas u
    canvas upcoming

By default shows all courses, only shows unlocked and unsubmitted assignments and uses colours to show urgency (green for submitted, orange for due in less than a week, red for due in less than 48 hours and blinking red for due in less than 24 hours).  

    -c         Display the output in compact style.
    -b         Enable blank mode so the output doesn't use colours.
    -f         Display only favourited courses.
    -l         Display assignments which haven't yet unlocked.
    -s         Display submitted assignments.
    -w         Include web links to the assignment at the end of each row. Might negatively impact appearance.
    -t         Display full course titles rather than shortened ones.
    -m [code]  Display only specific courses. Courses should be specified as numeric codes separated by a comma.

### Grades
Use with one of the following commands:

    canvas g
    canvas grades

By default shows all courses and uses colours to show the grade (red if < 40, orange if >= 80, green if = 100).

    -c         Display the output in compact style.
    -b         Enable blank mode so the output doesn't use colours.
    -f         Display only favourited courses.
    -w         Include web links to the assignment at the end of each row. Might negatively impact appearance.
    -t         Display full course titles rather than shortened ones.
    -m [code]  Display only specific courses. Courses should be specified as numeric codes separated by a comma.
    
### Notes
- Links are known to work in `terminator` and `gnome-terminal`, other terminal emulators may or may not support turning the assignment names into links. You can turn on the full URL links at the end of each row using the `-w` option.
- If both `-t` and `-m` are used, `-t` must be before `-m`
- `-m` should be a list of codes which match the course code exactly, separated by strings e.g. `-m "108,124"`. If the `-t` option is used, the codes provided to `-m` can be substrings of the full course title.
- To set your favourite courses, open up Canvas in a browser, and choose All Courses under the courses tab or navigate to `/courses`. You can click the star to favourite any courses you wish.

## Examples
    canvas u  
![Image showing result of command `canvas u`](imgs/u.png)  

    canvas u -cm "108,122"  
![Image showing result of command `canvas u -cm "108, 122"`](imgs/u-cm.png)  

    canvas g -cm "108"  
![Image showing result of command `canvas g -cm "108"`](imgs/g-cm.png)  

## Bugs/Contributing
If you find any bugs then please report it here on GitHub or drop me an email at <joe@joeherbert.dev>.  
If you want to contribute then feel free! Just make any changes and create a PR.  

## License
GNU General Public License v3.0
