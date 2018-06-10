# DatabaseTerminal

A vim plugin for use database console.  
This plugin supports only up Vim 8.1  

# Description

This plugin provides command to open terminal and start acess to database.  
This plugin support autorun database server.  
It may be usefull for practice.  
You can use \<Space>r mapping to send and run sql command in the terminal from your file.  
You can export execusion result to file by [Pandoc](https://pandoc.org/) or your own setting by variable.  

Note:  
This plugin is made for me. So if you install this plugin, it may occur some problems.  
This plugin can move on windows.Linux has support,It may be work because I don't debug.  

# Usage

You can use these Command or Mapping.  

## Commands

You can use these commands.  

+ :DbTerminal

    Open the terminal and start access database.  

+ :DbTOutput

    Output file to specified folder by g:DatabaseTerminal_folder and g:DatabaseTerminal_filename.  

+ :DbTStart

    Start Database server by manual.  

## Mapping

+ <Space>r

    This mapping provides you to run sql command of line under the cursor or selected area.  
    This mapping can use in sql file.

    Note:  
    You can use this mapping on normal mode and visual mode.  
    You can use this mapping on only opend terminal by :DbTerminal command.  

## Customization

There are many costomizable variables.  
See the document.  

# TODO

+ add option to ristrict how many terminals can open.

+ add option to customize size when opening terminal.


