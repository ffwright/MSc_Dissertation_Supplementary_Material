LaTex formatting describing the contents of this Supplementary Materials Folder. For an easier time reading the information contained in this file, see Appendix A of the main report.

data\_folder:
    \begin{itemize}
        \item Contains all the raw JSON data files supplied by Irithmics. Each file contains a set of forecasts and is identified by its London Stock Exchange ticker, ``ZZZZ.XLON'', and the announcement date that the file is centred on. This announcement date is also the last forecast generated within that file.
    \end{itemize}
    \item data\_processing\_and\_merging:
    \begin{itemize}
        \item data\_merging\_functions.R: 
        \begin{itemize}
            \item \verb|stitich_function| --- merges two data files by matching generation dates and deleting the overlap from the first file.
            \item  \verb|file_merge| --- a function that uses the \verb|stitich_function| to perform all viable merges between a list of dataframes.
            \item \verb|ticker_merge| --- a function that uses \verb|file_merge| to perform all possible merges for a specified company.
        \end{itemize}
        \item data\_merging\_script.R --- performs all possible merges and outputs ``merged\_raw\_data.rds''.
        \item ceemdan\_unscaled\_scaled.R --- a script that applies the \verb|CEEMDAN_function| to every merged data set using socketed parallelised foreach loops. This ensured that all other parts of our report were reproducible and saved time when producing plots. Produces both normalised scaled and un-normalised IMFs for use in other .R or .Rmd files.
    \end{itemize}
    \item functions:
    \begin{itemize}
        \item CEEMDAN\_function.R --- function to perform CEEMDAN with specified parameters and output a data frame that is used across the other files. This increased reproducibility.
        \item data\_merging\_functions.R --- duplicate of above
        \item significance\_test\_finctions.R:
        \begin{itemize}
            \item \verb|min_max| --- performs min-max normalisation.
            \item \verb|mean_period_func| --- calculates the mean period by counting maxima and dividing the length of the series by the number of maxima.
            \item \verb|energy_density_func| --- calcualtes the energy density by taking the sum of squares of an IMF dataframe.
            \item \verb|confidence_intervals_func| --- calculates the Wu test spread lines using the normal approximation for a given confidence-limit level.
        \end{itemize}
        \item step\_ahead\_expectation\_functions.R:
        \begin{itemize}
            \item \verb|expectation_time_extract| --- converts a normal data file into a reading along the diagonal data file.
            \item \verb|hm_plot_exp_space| --- plots the diagonal data as a colour map.
            \item  \verb|add_announcemnts_diag| --- adds the diagonal announcements dates to a transformed colour map 
        \end{itemize}
    \end{itemize}
    \item markdown\_html\_files:
    \begin{itemize}
        \item Contains the HTML files produced by the markdown documents used to generate plots and results for this report. It also contains a document describing the process of preparing the price data using Refinitiv Workspace.
    \end{itemize}
    \item price\_data\_prep:
    \begin{itemize}
        \item Price\_Data\_Preparation.Rmd --- markdown that prepares and extracts the dates required for acquiring price data using Refinitiv.
        \item long\_series\_date\_range.csv --- file input to in Refinitiv Workspace to get prices for the date range of each company.
    \end{itemize}
\item Refinitiv\_data:
\begin{itemize}
    \item This folder contains the excel documents used with Refinitiv Workspace to get price data. It also contains the .rds file produced by Price\_Data\_Preparation.Rmd to store the price data.
\end{itemize}
\item The rest of the folder is made up of the Rmarkdown files used to produce the HTML documents in the  markdown\_html\_files folder. This is also the project's main directory, and so contains almost all the .Rds objects produced and stored by different scripts contained in the above folders.