######################################################
# either to be executed within platformio
# ormanually with "python3.6 ./html2gzipc.py"
######################################################

#Import("env", "projenv")       # projenv only in post scripts!
if "Import" in globals():
    Import("env")

    my_flags = env.ParseFlags(env['BUILD_FLAGS'])
    defines = {k: v for (k, v) in my_flags.get("CPPDEFINES")}
else:
    # necessary to stay compatible with platformio
    env = {
        "PROJECT_DIR"                 : ".",
    }
    defines = {
        # values taken from build_flags if executed in platformio
        "USE_PRECOMPRESSED_WEB_FILES" : 1,          # use this for final release!
#        "USE_PRECOMPRESSED_WEB_FILES" : 0,          # use this for debugging!
        "WRITE_GZIPPED_WEB_FILES"     : 1
    }
import gzip
import os
import io
import sys
import re
import pprint



# usually the following values should not be changed, change env above (to set it in platformio give e.g. "-DWRITE_GZIPPED_WEB_FILES=1" in build_flags inside platformio.ini!
usePrecompressedFiles = 1                    # set to 1 to get html and js files precompressed (source code will be changed so these files are not really readable in browser anymore but much shorter!)
writeGzippedFiles     = 1                    # set to 1 to get gz files written (0 = gzipped stuff will only hold in memory)
htmlSubFolder         = "html"               # eth. that has to be built must be below of /src, HTML stuff has to be in a sub-folder
enumsFile             = "src/htmlEnums.h"
#enumsFile             = ""                  # with this line enabled htmlEnums.h will be ignored!
extensions            = [".html",     ".ico",         ".jpg",       ".png",      ".js",             ".css",     ".json"]                # insert all supported file extensions here (don't add .cpp or .h or you will get an endless loop!)
contentTypes          = ["text/html", "image/x-icon", "image/jpeg", "image/png", "text/javascript", "text/css", "application/json"]     # order must match with order of elements in extensions array!!!
getValueLeadingChar   = "X";


#if "Import" in globals():
#    print(env.Dump())
#else:
#    print(str(env))
print(str(defines))



def toolPrint(message):
    """
    print tool name followed by message to be printed, so user knows which code printed the message

    @type message:  string
    @param message: message to be printed
    """
    print("html2gzipc.py: ", end = "")
    print(message)



def convertUpperCaseUndersoreNotation(text):
    """
    Converts given text into "upper case underscore" notation

    @type message:  string
    @param message: text to be converted

    @rtype:         string
    @return:        converted text (e.g. "foo.bar" -> "FOO_BAR", "fooBar" -> "FOO_BAR", "foo bar" -> "FOO_BAR")
    """
    # if there is any non-uppercase character that is not "_" then convert given text
    if (re.search(r"[^A-Z_]", text)):
        text = re.sub(r"(?<!^)([A-Z])", r"_\1", text)       # replace all capital characters "[A-Z]" with "_[A-Z]"
        text = text.upper()                                 # upcase all characters
        text = re.sub(r"[^A-Z]",        r"_",   text)       # replace all characters not in [A-Z] with "_"
    return text     # already in correct notation



def createIncludeGuard(headerFileName):
    """
    Create valid include guard from given header filename (e.g. overallHtmlInclude.h)

    @type headerFileName:   string
    @param headerFileName:  name of header file a valid include guard has to be created, e.g. overallHtmlInclude.h -> OVERALL_HTML_INCLUDE_H
    """
    includeGuard = convertUpperCaseUndersoreNotation(headerFileName)
    if (not re.search(r"_H$", includeGuard)):
        includeGuard += "_H"                                            # ensure include guard ends with _H (if that is not the case usually sth. is really wrong!)

    return includeGuard



def createConstVariableName(fileName):
    """
    Create valid const variable name from given source filename (e.g. index.html)

    @type fileName:   string
    @param fileName:  name of source file a valid variable name has to be created, e.g. index.html -> index_html_gz
    """
    variableName = re.sub(r"\.",   r"_", fileName)        # replace all "." with "_"
    variableName += "_gz"
    variableName = variableName.lower()

    return variableName



def createConstNameVariableName(fileName):
    """
    Create valid const name variable name from given source filename (e.g. index.html)

    @type fileName:   string
    @param fileName:  name of source file a valid variable name has to be created, e.g. index.html -> index_html_gz_name
    """
    return createConstVariableName(fileName) + "_name"



def createContentTypeName(extension):
    """
    Create valid content type variable name from given extension (e.g. .html -> html_content_type)

    @type extension:    string
    @param extension:   extension a content type name has to be created
    """
    extension = re.sub(r"^\.", r"", extension)
    extension = extension.lower()
    extension += "_content_type"

    return extension



def createLengthDefinitionName(variableName):
    """
    Creates propper length definition name from variable name

    @type variableName:     string
    @param variableName:    variable name a length defition has to be created for

    @rtype:                 string
    @return:                returns length definition for given variable name (e.g. foo_bar -> FOO_BAR_LENGTH)
    """
    return variableName.upper() + "_LENGTH"



def createNameDefinitionName(variableName):
    """
    Creates propper name definition name from variable name

    @type variableName:     string
    @param variableName:    variable name a name defition has to be created for

    @rtype:                 string
    @return:                returns name definition for given variable name (e.g. foo_bar -> FOO_BAR_NAME)
    """
    return variableName.upper() + "_NAME"



def createReferenceDefinitionName(variableName):
    """
    Creates propper reference definition name from variable name

    @type variableName:     string
    @param variableName:    variable name a reference defition has to be created for

    @rtype:                 string
    @return:                returns reference definition for given variable name (e.g. foo_bar -> FOO_BAR_NAME)
    """
    return variableName.upper() + "_REFERENCE"



def createVariableDeclaration(variableName):
    """
    Creates propper variable declaration for given variable name

    @type variableName:     string
    @param variableName:    variable name a declaration has to be created for

    @rtype:                 string
    @return:                returns declaration for given variable name (e.g. foo_bar -> const uint8_t foo_bar[FOO_BAR_LENGTH])
    """
    return "const uint8_t " + variableName + "[" + createLengthDefinitionName(variableName) + "]"



def createNameDeclaration(nameVariableName):
    """
    Creates propper name declaration for given variable name

    @type nameVariableName:     string
    @param nameVariableName:    variable name a name declaration has to be created for

    @rtype:                     string
    @return:                    returns name declaration for given variable name (e.g. foo_bar -> const uint8_t foo_bar[FOO_BAR_LENGTH])
    """
    return "const String " + nameVariableName



def writeFileHeader(outputFileHandle, fileName = ""):
    """
    Write unified file header into given output file

    @type outputFileHandle:   file
    @param outputFileHandle:  handle where header has to be written to

    @type fileName:     string (optional)
    @param fileName:    name of the input file
    """
    # write header
    outputFileHandle.write("/*************************************************************\n")
    outputFileHandle.write(" * Created by html2gzipc.py\n")

    if (len(fileName)):
        outputFileHandle.write(" * source file was " + fileName + "\n")

    outputFileHandle.write(" *\n")
    outputFileHandle.write(" * DO NOT EDIT!!!\n")
    outputFileHandle.write(" *************************************************************/\n")
    outputFileHandle.write("\n\n\n")



def writeIncludeGuard(outputFileHandle, outputFileName):
    includeGuard = createIncludeGuard(outputFileName)
    outputFileHandle.write("#ifndef " + includeGuard + "\n")
    outputFileHandle.write("#define " + includeGuard + "\n")
    outputFileHandle.write("\n\n\n")



def writeSourceFile(targetFolder, fileName, includeFolder, data, sourceData = ""):
    """
    Write CPP source file containing constant variable with data as content

    @type targetFolder:     string
    @param targetFolder:    folder where source file has to be created to

    @type fileName:         string
    @param fileName:        file name of the input file

    @type data:             bytearray
    @param data:            array containing binary data
    """
    # open output file
    with open(targetFolder + fileName + ".cpp", "wt") as outputFile:
        # write unified file header
        writeFileHeader(outputFile, fileName)

        # include necessary headers
        outputFile.write("#include <Arduino.h>\n")                                      # because of String
        outputFile.write("#include <cstdint>\n")                                        # because of uint8_t
        outputFile.write("#include <pgmspace.h>\n")                                     # because of PROGMEM
        outputFile.write("#include \"" + includeFolder + "/" + fileName + ".h\"\n")     # include own header file because of length definition
        outputFile.write("\n\n\n")

        # write const declaration
        nameVariableName = createConstNameVariableName(fileName)
        nameDeclaration  = createNameDeclaration(nameVariableName)
        variableName     = createConstVariableName(fileName)

        outputFile.write(nameDeclaration     + " = \"" + fileName + "\";\n")
        variableDeclaration = createVariableDeclaration(variableName) + " PROGMEM = {"
        outputFile.write(variableDeclaration + "\n")

        # write binary data 16-byte wise
        hexLine = ""
        for byteIndex in range(len(data)):
            # end of line reached or current character is last one?
            if ((byteIndex and byteIndex % 16 == 0) or byteIndex == (len(data) - 1)):
                outputFile.write(hexLine + "\n")    # write collected hex line
                hexLine = ""                        # prepare variable for next turn

            # begin of line?
            if (byteIndex % 16 == 0):
                hexLine += "    "                   # add indentation

            # convert current byte into hex string (e.g. 64 -> "0x64")
            hexLine += "0x%0.2X" % data[byteIndex]

            # further characters left?
            if (byteIndex < (len(data) - 2)):
                hexLine += ", "                     # prepare current line for next byte

        # close data structure
        outputFile.write("};\n")
        outputFile.write("\n\n\n")

        # write original source file
        if (len(sourceData)):
            outputFile.write("#if 0\n")
            outputFile.write("/*\n")
            sourceData = sourceData.replace(b'\r', b'')     # remove CRs if exists since otherwise we will get duplicated newlines when decoding sourceData with utf-8
            outputFile.write(sourceData.decode("utf-8"))
            outputFile.write("*/\n")
            outputFile.write("#endif\n")
            outputFile.write("\n\n\n")



def writeHeaderFile(targetFolder, fileName, dataSize):
    """
    Write header file containing constant variable extern declaration and length definition

    @type targetFolder:     string
    @param targetFolder:    folder where source file has to be created to

    @type fileName:         string
    @param fileName:        file name of the input file

    @type dataSize:         int
    @param dataSize:        size of data stored into CPP file, used for length definition
    """
    # open output file
    with open(targetFolder + fileName + ".h", "wt") as outputFile:
        # write unified file header
        writeFileHeader(outputFile, fileName)

        # write include guard
        writeIncludeGuard(outputFile, fileName)

        # include necessary headers
        outputFile.write("#include <Arduino.h>\n")              # because of String
        outputFile.write("#include <cstdint>\n")                # because of uint8_t
        #outputFile.write("#include <pgmspace.h>\n")
        outputFile.write("\n\n\n")

        # length definition and variable declaration
        variableName     = createConstVariableName(fileName)
        nameVariableName = createConstNameVariableName(fileName)

        referenceDefinition = createReferenceDefinitionName(variableName)
        nameDefinition      = createNameDefinitionName(variableName)
        lengthDefinition    = createLengthDefinitionName(variableName)
        variableDeclaration = createVariableDeclaration(variableName)
        nameDeclaration     = createNameDeclaration(nameVariableName)

        outputFile.write("#define " + referenceDefinition + " "      + variableName     + "\n")
        outputFile.write("#define " + nameDefinition      + "      " + nameVariableName + "\n")
        outputFile.write("#define " + lengthDefinition    + "    "   + str(dataSize)    + "\n")
        outputFile.write("\n\n\n")

        outputFile.write("extern " + variableDeclaration + ";\n")
        outputFile.write("extern " + nameDeclaration     + ";\n")
        outputFile.write("\n\n\n")

        # lead out
        outputFile.write("#endif\n")
        outputFile.write("\n\n\n")



def writeOverallHeaderFile(targetFolder, headerFilesFolder, headerFilesArray):
    """
    write given data together with header and include guard into given destination header file

    @type targetFolder:         string
    @param targetFolder:        folder where source file has to be created to

    @type headerFilesFolder:    string
    @param headerFilesFolder:   folder where header files have been created

    @type headerFilesArray:     file
    @param headerFilesArray:    array containing all defined variables

    @rtype:                     string
    @return:                    returns used overall file name
    """
    overallFileName = "overallHtmlInclude.h"
    with open(targetFolder + overallFileName, "wt") as outputFile:
        # write header
        writeFileHeader(outputFile)

        # write include guard
        writeIncludeGuard(outputFile, overallFileName)

        # include headers
        outputFile.write("#include <Arduino.h>\n")
        outputFile.write("#include <ESPAsyncWebServer.h>\n")
        for headerFile in headerFilesArray:
            outputFile.write("#include \"" + headerFilesFolder + headerFile + ".h\"\n")
        outputFile.write("\n\n\n")

        # create content types for all given extensions
        for contentIndex in range(len(extensions)):
            contentName = createContentTypeName(extensions[contentIndex])
            outputFile.write("const String " + contentName + " = \"" + contentTypes[contentIndex] + "\";\n")
        outputFile.write("\n\n\n")

        # length definition for overallHtmlInclude array
        overallHtmlIncludeLength = createLengthDefinitionName(convertUpperCaseUndersoreNotation("overallHtmlInclude"))
        outputFile.write("#define " + overallHtmlIncludeLength + " " + str(len(headerFilesArray)) + "\n")

        # structure to handle all HTML stuff (.html, .ico, .jpg, ...), i.e. eth. that can be requested by a web client)
        outputFile.write("struct {\n")
        outputFile.write("    const String   * fileName;\n")
        outputFile.write("    const String   * contentType;\n")
        outputFile.write("    const uint8_t  * gzippedData;\n")
        outputFile.write("    const uint32_t   dataLength;\n")
        outputFile.write("    void          (* handler)(AsyncWebServerRequest *request);\n")
        outputFile.write("} overallHtmlInclude[" + overallHtmlIncludeLength + "] = {\n")

        # create structure for all created header files so requests can be handled automatically without registering all supported requests
        for headerFile in headerFilesArray:
            variableName        = createConstVariableName(headerFile)
            referenceDefinition = createReferenceDefinitionName(variableName)
            nameDefinition      = createNameDefinitionName(variableName)
            lengthDefinition    = createLengthDefinitionName(variableName)

            extension = os.path.splitext(headerFile)[1]
            extension = re.sub(r"^\.", r"", extension)
            contentType = createContentTypeName(extension)

            outputFile.write("    {\n")
            outputFile.write("        &" + nameDefinition + ", &" + contentType + ", " + referenceDefinition + ", " + lengthDefinition + ", NULL\n")
            outputFile.write("    },\n")

        outputFile.write("};\n")
        outputFile.write("\n\n\n")

        # lead out
        outputFile.write("#endif\n")
        outputFile.write("\n\n\n")

        return overallFileName





################ [main] #########################
if "USE_PRECOMPRESSED_WEB_FILES" in defines:
    usePrecompressedFiles = int(defines["USE_PRECOMPRESSED_WEB_FILES"])     # int() is necessary for platformio!

if "WRITE_GZIPPED_WEB_FILES" in defines:
    writeGzippedFiles = int(defines["WRITE_GZIPPED_WEB_FILES"])             # int() is necessary for platformio!

htmlOutputFolder        = env["PROJECT_DIR"] + "/src/" + htmlSubFolder
htmlSourceFolder        = env["PROJECT_DIR"] + "/" + htmlSubFolder
htmlPreCompressedFolder = env["PROJECT_DIR"] + "/" + htmlSubFolder + "/compressed"

if usePrecompressedFiles:
    # take pre-compressed ones
    toolPrint("set compressed folder " +  str(usePrecompressedFiles))
    htmlInputFolder = htmlPreCompressedFolder
else:
    # take original ones
    htmlInputFolder = htmlSourceFolder

if writeGzippedFiles:
    # since zipping is done inside the script, gzipped files are not really needed, but will be written for logging if activated
    gzFolder        = env["PROJECT_DIR"] + "/" + htmlSubFolder + "/gzipped"

enumsFileName = env["PROJECT_DIR"] + "/" + enumsFile


# show some information
toolPrint("PROJECT_DIR: " + env["PROJECT_DIR"])
toolPrint("HTML_FOLDER: " + htmlOutputFolder)
toolPrint("html input folder: " + htmlInputFolder)
if usePrecompressedFiles:
    toolPrint("precompressed html files will be used")
if writeGzippedFiles:
    toolPrint("gzipped html files will be written for logging")


toolPrint("searching for html files...")

if (not os.path.exists(htmlOutputFolder)):
    toolPrint("output folder doesn't exist: " + htmlOutputFolder)
    raise OSError(42, "output folder doesn\'t exist", htmlOutputFolder)


createdHeaderFiles = []         # to collect all created header files to create final overall include file

# search all supported files in the order given in extensions (so it's possible to sort files to fit request order for better performance)
filesToBeHandled = []
for extension in extensions:
    toolPrint("search in : " + htmlInputFolder)
    for supportedFileName in os.listdir(htmlInputFolder):
        if supportedFileName.endswith(extension):
            filesToBeHandled.append(supportedFileName)

#print(*filesToBeHandled, sep='\n')

# load enums for html replacement
enums = {}
try:
    if len(enumsFile):
        with open(enumsFileName, "r") as enumsFile:
            lineCounter  = 0
            matchedEnums = 0
            # read until "enum {" has been found
            line = ""
            while not re.search(r"^enum {$", line):
                lineCounter += 1
                line = enumsFile.readline()

            # eof reached?
            if not line:
                toolPrint("no line contains \"enum {\" in " + enumsFileName)
                raise ValueError(42, "no line contains \"enum {\" in ", enumsFileName)

            # handle all enum entries
            while not re.search(r"^};$", line):
                lineCounter += 1
                line = enumsFile.readline()

                if re.search(r"^};$", line):
                    break;

                # ignore empty lines and lines with comments
                if re.search(r"^ *(//.*)?$", line):
                    continue

                # try to match valid line "       __FOOBAR__,   // any comment stuff"
                match = re.search(r"^ *([A-Z_]+) *,.*$", line)
                if not match:
                    toolPrint("invalid line found in " + enumsFileName + "::" + str(lineCounter) + " [ " + line + "]")
                    raise ValueError(42, "invalid line found in " + enumsFileName + "::" + str(lineCounter), line)

                enums[match[1]] = getValueLeadingChar + str(matchedEnums)
                matchedEnums += 1

            if not line:
                toolPrint("no line contains \"};\" in " + enumsFileName)
                raise ValueError(42, "no line contains \"};\" in ", enumsFileName)
except EnvironmentError as err:
    toolPrint(f"Unexpected " + str(err) + ", " + str(type(err)))
    raise
#pprint.pprint(enums)


# handle all found supported files and convert them into includable CPP and header files
for supportedFileName in filesToBeHandled:
    toolPrint("convert [" + supportedFileName + "]...")

    supportedFileNameFullPath = htmlInputFolder + "/" + supportedFileName

    try:
        with open(supportedFileNameFullPath, "rb") as inputFile:
            sourceData = inputFile.read()                                   # read input file (byte)

            for key in enums.keys():
                value = enums[key]
                sourceData = sourceData.replace(bytes(key, 'utf-8'), bytes(value, 'utf-8'))

            compressedData = gzip.compress(sourceData)                      # compress input file data with gzip
            toolPrint("compressed...")
            #print(compressedData)

            # gzip files are not necessary since data is hold in memory but for debugging it could be nice to get the gzipped stuff (for this set writeGzippedFiles to 1)
            if (writeGzippedFiles):
                if (os.path.exists(gzFolder)):
                    with open(gzFolder + "/" + supportedFileName + ".gz", "wb") as zippedFile:
                        zippedFile.write(compressedData)
                        toolPrint("compressed file written [" + supportedFileName + ".gz]...")
                else:
                    toolPrint("temporary folder doesn't exist: " + gzFolder)
                    raise OSError(42, "temporary folder doesn\'t exist", gzFolder)

            writeSourceFile(htmlOutputFolder + "/",
                            supportedFileName,
                            htmlSubFolder,
                            compressedData,
                            sourceData if supportedFileName.endswith("html") else "")       # write gzipped html stuff into cpp file

            writeHeaderFile(htmlOutputFolder + "/", supportedFileName, len(compressedData))       # write extern declaration and length definition into h file

            createdHeaderFiles.append(supportedFileName)                                    # source file created, so store variable name for "extern" declaration
            toolPrint("source files created [" + supportedFileName + ".cpp/.h]...")
    except EnvironmentError as err:
        toolPrint(f"Unexpected " + str(err) + ", " + str(type(err)))
        raise

# create overall include file with all extern declarations from HTML files
if (len(createdHeaderFiles)):
    try:
        overallFileName = writeOverallHeaderFile(htmlOutputFolder + "/", htmlSubFolder + "/", createdHeaderFiles)
        toolPrint("overall include file created [" + overallFileName + "]...")
    except EnvironmentError as err:
        toolPrint(f"Unexpected " + str(err) + ", " + str(type(err)))
        raise
else:
    toolPrint("no source files created")
    raise


