---
output:
  word_document: default
  html_document: default
---

1. Are the objectives and the rationale of the study clearly stated?

[Reviewer #1:]{.underline} The objectives and rationale for this study are clearly described. 

[Reviewer #2:]{.underline} Yes. 

2. If applicable, is the application/theory/method/study reported in sufficient detail to allow for its replicability and/or reproducibility?

[Reviewer #1:]{.underline}

Please provide additional detail in the methods section on how the age-length keys (ALKs) were constructed. Specifically, how was the bin structure selected (single or multi-centimeter bins)? Was this choice adjusted to be consistent with the range of lengths observed for each species and/or the specific bin structure that is used in the stock assessments?

**Response: In the revision we have included additional text in an effort to clarify our expansion methods and to provide additional detail on how the ALKs were constructed. Specifically, we have indicated in the methods section that we are binning the length frequency (and subsequent age-length key) to 1 cm bins, that was across the range of lengths for each species and followed the bin structure used in the assessments. We also note that the framework we have constructed allows for any bin structure. In a related paper (Hulson et al, in press) we use a similar framework (without the ageing error and growth variablity features presented in this work) to evaluate the effects of different bin structures (1 cm, 2 cm, and 5 cm). From those results we note that the bin structure did have an effect on the length composition ISS, but this was not translated to the age composition ISS, which was unaffected by the choice of bin size. For a subset of species as an example (Gulf of Alaska Pacific ocean perch and Walleye pollock) we have also evaluated bin structure for this work and have found... as shown in the following figure. We have included these results in the revision (?)**

It is somewhat unclear from the methods, but I think that the “total” or combined-sex results were created by summing the male and female age compositions. Would the ‘total’ age composition be better estimated by combining males and females prior to creating the age-length key and therefore not including the bootstrapped variability of each sex separately in the total? Would this be the appropriate method if the stock assessment were intending to use the aggregate distribution? With a larger sample size, albeit possibly also with more growth variability, would the input sample sizes would be larger using this method?

**Response: We recognize that the reviewer is correct that we left it unclear as to how the combined-sex results were created and have added text to the revised methods section that describe that the combined-sex results were created by summing the male, female, and unsexed expanded population numbers-at-length and -age to then compute the total length and age compositions, as the reviewer noted. The primary reason this is done is to account for the potential differences in growth between sexes (for example, for flatfish species), albeit, the reviewer makes an interesting point that the increased sample size could translate to an increased ISS. We were curious about this and ran an example for a two species that don't exhibit difference in growth between sexes (Gulf of Alaska Pacific Ocean perch and Walleye pollock). The following figuyre shows... Thus, we did such and such in the revision...**

Were the age samples in this study collected randomly in each year or were there stratified targets by length? If length-stratified in some years (which would seem best for the ALK approach), but random in other years (perhaps best for building age compositions without an ALK and having more variability when used with an ALK) would the interaction with ageing imprecision be different? If so, should the results be delineated between years with different sampling methods?

**Response: The reviewer is correct that sampling methodology has changed across time as it pertains to age collections on AFSC bottom trawl surveys. It has been the case that for species assessed with SCAA models at AFSC the transition has been from length-stratified to random sampling, where currently all species assessed with SCAA models at AFSC are collected randomly. However, we note that the collection of otoliths isn't completely random, at least in the 'simple random sampling' sense. This is because the number of otoliths within any given haul are capped at some level for all these species (for example, 2 fish per haul for arrowtooth founder, as compared to 5 fish per haul for Pacific ocean perch) and not collected proportionally to catch. There are two primary complications that this creates when considering building an age composition without an ALK. First, these haul level samples would need to be weighted in some form, whether by catch or cpue of the haul. Second, at the strata level the number of otoliths collected is much smaller than the length frequency collections, so expansion by some sort of catch weighting at the strata scale would be problematic when only using age data. This remains true at any spatial scale of age versus length frequency sampling. To overcome these complications would involve developing new expansion methods, which we have not done in the revision as we feel whatever expansion methods we would develop would neither mimic what is done at AFSC, or anywhere else for that matter. We would also suggest, that regardless of the age sampling methodology employed (length-stratified or random) that one would consider using an ALK expansion approach. Given the large difference in the magnitude of sampling between length frequency and age on most surveys one should consider leveraging the information contained in the length frequency when developing age composition through the ALK approach. To the reviewers main point, of whether ageing imprecision would have a different impact on ISS if age composition were computed through an ALK or not, we hypothesize that the impact would be similar, at least in the sense that the ISS would decrease with the added variability that ageing imprecision adds. However, we have not tested that here and have noted as such in the revision in which we include a caveats paragraph in the discussion section.**

3. If applicable, are statistical analyses, controls, sampling mechanism, and statistical reporting (e.g., P-values, CIs, effect sizes) appropriate and well described?

[Reviewer #1:]{.underline}

The bootstrap approach is appropriate and the manuscript extends previous work on input sample size calculations from length and age compositions for use in fisheries stock assessment. My biggest concern is with regard to the pooling across years of the age-length key and the influence that may have on the results:
A primary focus of the manuscript is the proportional contribution of growth variability to the reduction in input sample size. However, the method uses a ‘global’ ALK pooled across all years and areas. I’m assuming that assessments would normally use a year-specific key, which would not have the effects of interannual growth differences and/or strong cohorts in a single key pooled over time. If the pooled approach does not match what is done in assessments, it would seem to overestimate the reduction in input sample size due to growth. Would it be possible to add an example to the analysis comparing the results based on pooled vs annual ALKs for one of the species with a large growth effect on the input sample size (e.g. a gadid)?

**Response: As a point of clarification: a global ALK was not used to compute the annual age compositions, but the age-length pairs for estimating growth variablity was. Using the same example species as in previous responses (Gulf of Alaska Pacific ocean perch and Walleye pollock) we ran an example for to show the differences between pooled and annual growth data... Due to these results we did such and such in the revision... many assessments pool age-length data to estimate growth**

[Reviewer #2:]{.underline}

Additional details about the estimated relationships between nominal and input sample sizes should be added as noted in the review.

**Response: we added a table...**

4. Could the manuscript benefit from additional tables or figures, or from improving or removing (some of the) existing ones?

[Reviewer #1:]{.underline}

I think it would be helpful to include a figure/panels showing results similar to the upper panels of figure 5, but comparing with the age range in the observed data for each species and also the number of length bins with data for the ALK for that species. Perhaps these have more of a clear effect than the CVs?

**Response: Hmm, these might be interesting** 

Figure 2 (and other boxplots): What is shown by these boxplots - median, 25th, 75th and range?

**Response: A description of what is shown in the boxplots has been added to the figure captions.** 

Figure 4, upper panel: These axes should not extend below, as that space has no meaning. Also, the ellipses need a description in the caption: why do they extend far below the points (are they forced to cover 0,0)?, do/should they have 95% coverage of the points?

**Response:**  **easy fix using coord_cartesian(xlim = c(0, Inf), ylim = c(0, Inf)), I suppose the reason for the below 0,0 is that they are not computed on a log scale? Maybe jsut show relationships with linear line...**

Figure 5 lower panel: These results seem inconsistent with figure 3 as the whiskers all extend above a value of 1.0 (but not in Figure 3). Is it possible that the bootstrapped values and not the annual harmonic means are being plotted here?

**Response: Need to think on this one a bit - certainly showing different things (lumped vs split) - also might want to explain what the error bar is in Fig 5.** 

[Reviewer #2:]{.underline} 

Yes, it would be useful to provide a table with summary statistics for the results shown in Figure 4.

**Response: A table has been included...** 

5. If applicable, are the interpretation of results and study conclusions supported by the data?

Please provide suggestions (if needed) to the author(s) on how to improve, tone down, or expand the study interpretations/conclusions. Please number each suggestion so that the author(s) can more easily respond.

[Reviewer #1:]{.underline} Yes. But see comments on the use of the pooled ALK.

[Reviewer #2:]{.underline} Yes.

6. Have the authors clearly emphasized the strengths of their study/theory/methods/argument?

[Reviewer #1:]{.underline} Yes

[Reviewer #2:]{.underline} Yes

7. Have the authors clearly stated the limitations of their study/theory/methods/argument?

[Reviewer #1:]{.underline}

Per the above comments on the ALK approach, the relative effect of growth on input sample size may be overestimated; however an example comparison for one species with large variability due to growth could address this.

**Response:** 

[Reviewer #2:]{.underline}

No, they need to provide more context about alternative approaches to accounting for ageing error and growth variability in stock assessments.

**Response:** 

8. Does the manuscript structure, flow or writing need improving (e.g., the addition of subheadings, shortening of text, reorganization of sections, or moving details from one section to another)?

[Reviewer #1:]{.underline} The manuscript is well written and organized.

[Reviewer #2:]{.underline} The flow and structure are fine.

9. Could the manuscript benefit from language editing?

[Reviewer #1:]{.underline}  No

[Reviewer #2:]{.underline} No

[Reviewer #1:]{.underline}  Minor editorial corrections:

Lines 153-155: Which years were included in this analysis?

**Response: corrected** 

Line 339: "Bias"

**Response: corrected** 

Line 380: Instead of "half-way", perhaps consider "partially" since the relative magnitude of the effects from ageing error in the assessment and in the ISS bootstrap have not been quantified.

**Response: corrected** 

Line 400: "as example"

**Response: corrected** 

Line 403: "has largest" "and smallest"

**Response: corrected** 

[Reviewer #2:]{.underline} Big picture comments

The manuscript provides a valuable estimate of adjustments that should be made to account for input sample sizes (ISS) in statistical catch-at-age models in which length compositions are converted to age compositions using an age-length key. This approach is used at the Alaska Fisheries Science center where the authors work and in many other places. The manuscript is technically sound and surely valuable for improving the assessments at AFSC. However, it has some major gaps when it comes to providing context for this approach.

First, I believe the manuscript does not adequately compare their approach to the alternative in which length compositions are input directly into the model and fit to expected compositions calculated from a growth curve and estimated variability in length at age each. That alternative approach allows ageing error (as well as potentially process error in growth and selectivity) to be incorporated directly into the model, and was used by Thorson and Haltuch (2019) as well as in the assessments of all the stocks explored by Stewart and Hamel (2014). The paragraph starting on line 368 suggests that incorporation of ageing error in the calculation of expected age compositions addresses only half of the problem, but when length compositions are used directly, there is no need for incorporation of ageing error or growth variability in the calculation of input sample size.

**Response: need to explain the difference between the modeled and observed quantities, that both contain these sources of error, and that the data weighting applied to the fit between the two should also include these sources of error. when fitting caal would still need an iss that has growth and ageing error accounted for. but, more work to be done on how to develop iss for caal data.**

Second, the manuscript does not address other data weighting approaches, such as the iterative approach developed by Francis (2011) or those that include estimated parameters promoted by Thorson (numerous, including 2023 paper co-authored by the lead author of this manuscript). It would be useful to see how the down-weighting calculated via a model-based data-weighting method compared to the adjustments proposed in the manuscript.

**Response: beyond scope of current ms, but a study dealing with implcations of starting values for iss would be useful. hve shown that misspecifying these values can cause bias, with the implication that not accounting for these sources of error could cause bias. add para to discussion on this**

Minor issues

Line 54: "obtained from hauls within a trip that is targeting a specific species"
Perhaps this is the norm in Alaska, but in much of the world it's more common to sample trips, not hauls, and most fisheries do not target a single species.

**Response: corrected - adjusted text to reflect that either hauls or trips may be sampled and that multiple species may be targeted**

Line 66: "The statistical weight assigned to annual composition data…" The statistical weight is often a combination of one of the methods listed and some adjustment applied within the model according to some data-weighting scheme.
 
**Response: Guess we should clarify that it is the input weight? not all models run iterative reweighting.**
  
Line 81: the proposed naming convention is valuable and welcome

**Response: corrected** 

Line 97: "duet o" to "due to"

Line 108: "a number of studies" is supported only by a single reference: "Liao et al. (2013).

Line 212: "Growth variability was incorporated by resampling from all lengths associated with a given age and sex." This is confounded with ageing error. Even if there were zero variability in growth, this calculation would show a range of lengths associated with a given age due to ageing error except for ages beyond the point where growth had reached an asymptote.

**Response: totally, how to address this...**

Line 303: "A positive relationship is observed, by species group, between the number of age samples taken per haul and the age composition ISS per sampled haul (top panel of Figure 4)." It would be useful to provide a table with summary statistics for the results shown in Figure 4: the average input sample size per nominal age sample and/or the average ISS per haul. This would make it easier to compare to the results of Stewart and Hamel (2014) and to adjust nominal sample sizes without repeating the bootstrap procedure.

**Response: add a table, but note that the realtionship is extremely variable and it wouldn't be as simple as adjusting nominal sample size and that hte bs should be run for each new year, doesn't need to be run for the whole time series**

Line 416: Change "...the package we built…" to "...the R package we built…". The DESCRIPTION file in the R package should be updated so that the citation could be filled in so that the information at https://benwilliams-noaa.github.io/surveyISS/authors.html#citation is more complete (that same information is provided by the R command citation("iss") if the package is installed.

**Response: corrected** 

Line 575: "Number ages" to "Number of ages"

**Response: corrected**

Line 580: "plts" to "plots"

**Response: corrected**

Line 580: "elipses" to "ellipses" 

**Response: corrected**

Also, some explanation of how the ellipses were calculated would be useful. Adding a linear regression may also be useful.

**Response: maybe just switch to linear for all**

From the editor (Andre Punt)
The reviewers raise several very relevant and important points. Reviewer #2 requests consideration of some broader issues. You should either adopt these or provide reasons why this is not appropriate. I am likely to request a 2nd review of the MS by reviewer #2
