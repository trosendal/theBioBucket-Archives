# File-Name: GScholarScraper_3.2.R
# Date: 2013-07-11
# Author: Kay Cichini
# Email: kay.cichini@gmail.com
# Purpose: Scrape Google Scholar search result
# Packages used: XML
# Licence: CC BY-SA-NC
#
# Arguments:
# (1) input:
# A search string as used in Google Scholar search dialog
#
# (2) write:
# Logical, should a table be writen to user default directory?
# if TRUE ("T") a CSV-file will be created.
#
# Difference to version 3:
# (3) added "since" argument - define year since when publications should be returned..
# defaults to 1900..
#
# (4) added "citation" argument - logical, if "1" citations are included
# defaults to "0" and no citations will be included..
# added field "YEAR" to output
#
# Caveat: if a submitted search string gives more than 1000 hits there seem
# to be some problems (I guess I'm being stopped by Google for roboting the site..)
#
# And, there is an issue with this error message:
# > Error in htmlParse(URL):
# > error in creating parser for http://scholar.google.com/scholar?q
# I haven't figured out his one yet.. most likely also a Google blocking mechanism..
# Reconnecting / new IP-address helps..


GScholar_Scraper <- function(input, write = F) {

    require(XML)

    # flip values because the url uses 0 for inclusion of citations
    citation <- ifelse(citation == 1, 0, 1)

    ## putting together the search-URL:
    URL <- paste0("https://scholar.google.se/scholar?as_q=", input, "&as_sdt=1,5")
    cat("\nThe URL used is: ", "\n----\n", paste0("* ", "http://scholar.google.com/scholar?q=", input, "&as_sdt=1,5&as_vis=",
                 citation, "&as_ylo=", since, " *"))

                                        # get content and parse it:
    doc <- readLines(URL)
    doc <- htmlParse(doc)

    # number of hits:
    h1 <- xpathSApply(doc, "//div[@id='gs_ab_md']", xmlValue)
    h2 <- unlist(strsplit(h1, "\\s"))
    # in splitted string it is the second element which contains digits,
    # grab it and remove decimal signs and convert to integer
    num <- as.integer(gsub("[[:punct:]]", "", h2[grep("\\d", h2)[1]]))
    cat("\n\nNumber of hits: ", num, "\n----\n", "If this number is far from the returned results\nsomething might have gone wrong..\n\n", sep = "")

    # If there are no results, stop and throw an error message:
    if (num == 0 | is.na(num)) {
        stop("\n\n...There is no result for the submitted search string!")
    }

    pages.max <- ceiling(num/20)

    # 'start' as used in URL:
    start <- 20 * 1:pages.max - 20

    # Collect URLs as list:
    URLs <- paste("https://scholar.google.com/scholar?start=", start, "&as_q=", input,
                  "&num=20&as_sdt=1,5", sep = "")
    scraper_internal <- function(URL) {

        doc <- readLines(URL)
        doc <- htmlParse(doc, encoding="UTF-8")

        # titles:
        tit <- xpathSApply(doc, "//h3[@class='gs_rt']", xmlValue)

        # publication:
        pub <- xpathSApply(doc, "//div[@class='gs_a']", xmlValue)

        # summaries are truncated, and thus wont be used..
        # abst <- xpathSApply(doc, '//div[@class='gs_rs']', xmlValue)
        # ..to be extended for individual needs
        options(warn=(-1))
        dat <- data.frame(TITLES = tit, PUBLICATION = pub,
                          YEAR = as.integer(gsub(".*\\s(\\d{4})\\s.*", "\\1", pub)))
        options(warn=0)
        sleeptime <- abs(runif(100)*30) + 10 ## Sleep for a random time between 10 and 40 seconds
        Sys.sleep(sleeptime)
        return(dat)
    }

    result <- do.call("rbind", lapply(URLs, scraper_internal))
    if (write == T) {
      write.table(result, "GScholar_Output.CSV", sep = ";",
                  row.names = F, quote = F)
      shell.exec("GScholar_Output.CSV")
      } else {
      return(result)
    }
}

# EXAMPLES:
# 1:
input <- "asf+asfv&as_epq=african+swine+fever&as_oq=%22hog+cholera%22+carrier+persist+reservoir+survivor+intermittent+chronic+subclinical+latent+seropositive+resist&as_eq=&as_occt=any&as_sauthors=&as_publication=&as_ylo=&as_yhi=&hl=sv"
df <- GScholar_Scraper(input)
nrow(df)
