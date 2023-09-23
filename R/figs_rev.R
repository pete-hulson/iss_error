
# load ----
library(tidyverse)
library(tidytable)
library(vroom)
library(here)
library(purrr)
library(rsample)
library(data.table)
library(scico)
library(extrafont)
library(cowplot)
library(egg)
library(ggplot2)
library(gg.layers)
# remotes::install_version("Rttf2pt1", version = "1.3.8")
# remotes::install_github("rpkgs/gg.layers")
# extrafont::font_import()
loadfonts(device="win")   

# if you get a lot of messages like 'C:\Windows\Fonts\ALGER.TTF : No FontName. Skipping.'
# then load this package and then run font_import
# remotes::install_version("Rttf2pt1", version = "1.3.8")

# add fonts to all text (last line)
ggplot2::theme_set(
  ggplot2::theme_light() +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      # axis.ticks.length = grid::unit(base_ / 2.2, "pt"),
      strip.background = ggplot2::element_rect(fill = NA, colour = NA),
      strip.text.x = element_text(colour = "black"),
      strip.text.y = element_text(colour = "black"),
      panel.border = element_rect(fill = NA),
      legend.key.size = grid::unit(0.9, "lines"),
      legend.key = ggplot2::element_rect(colour = NA, fill = NA),
      legend.background = ggplot2::element_rect(colour = NA, fill = NA),
      text = element_text(family = "Times New Roman")
    )
)

# pull in output ----

if(!file.exists(here::here('output', 'afsc_iss_err_full.csv'))){
  
  spec <- vroom::vroom(here::here('data', 'species_code_name.csv')) # species_code and common names
  
  r_t <- vroom::vroom(here::here('data', 'reader_tester.csv'))
  
  specimen <- vroom::vroom(here::here('data', 'specimen_ai.csv')) %>% 
    tidytable::mutate(region = 'ai') %>% 
    tidytable::bind_rows(vroom::vroom(here::here('data', 'specimen_bs.csv')) %>% 
                           tidytable::mutate(region = 'bs')) %>% 
    tidytable::bind_rows(vroom::vroom(here::here('data', 'specimen_goa.csv')) %>% 
                           tidytable::mutate(region = 'goa'))
  
  err_iss <- vroom::vroom(here::here('output', 'afsc_iss_err_rev.csv'))
  
  surv_labs <- c("Aleutian Islands", "Eastern Bering Sea Shelf", "Gulf of Alaska")
  names(surv_labs) <- c("ai", "bs", "goa")
  
  # add specimen info to iss results
  
  specimen %>% 
    tidytable::drop_na() %>% 
    tidytable::summarise(nhls = length(unique(hauljoin)),
                         nss = length(age),
                         max_len = max(length),
                         min_len = min(length),
                         max_age = max(age),
                         min_age = min(age), .by = c(year, species_code, region, sex)) %>% 
    tidytable::filter(sex != 3) %>% 
    tidytable::mutate(comp_type = case_when (sex == 1 ~ 'male',
                                             sex == 2 ~ 'female')) %>% 
    tidytable::select(-sex) %>% 
    tidytable::bind_rows(specimen %>% 
                           tidytable::drop_na() %>% 
                           tidytable::summarise(nhls = length(unique(hauljoin)),
                                                nss = length(age),
                                                max_len = max(length),
                                                min_len = min(length),
                                                max_age = max(age),
                                                min_age = min(age), .by = c(year, species_code, region)) %>% 
                           tidytable::mutate(comp_type = 'total')) %>% 
    tidytable::mutate(len_range = (max_len - min_len) / 10,
                      age_range = (max_age - min_age)) %>% 
    tidytable::select(-max_len, -min_len, -max_age, -min_age) -> samp_dat
  
  species = unique(err_iss$species_code)
  
  r_t %>% 
    tidytable::filter(species_code %in% species,
                      Region %in% c('AI', 'BS', 'BS/AI', 'BS_GOA', 'BSAI', 'BSGOA', 'GOA')) %>% 
    dplyr::rename_all(tolower) %>% 
    tidytable::select(species_code, read_age, test_age) %>% 
    tidytable::drop_na() %>% 
    tidytable::filter(read_age > 0) %>% 
    tidytable::mutate(diff = abs(read_age - test_age) / read_age) %>% 
    tidytable::summarise(ape1 = sum(diff),
                         R = length(diff),
                         cv_a = sd(test_age) / read_age, .by = c(species_code, read_age)) %>% 
    tidytable::summarise(ape2 = sum(ape1 / R),
                         N = sum(R),
                         cv_a = mean(cv_a, na.rm = TRUE), .by = c(species_code)) %>% 
    tidytable::mutate(ape = 100 * ape2 / N) %>% 
    tidytable::select(species_code, ape, cv_a) -> ape
  
  specimen %>% 
    tidytable::drop_na() %>% 
    tidytable::summarise(sd_l1 = sd(length),
                         cv_l = sd(length) / mean(length), .by = c(species_code, sex, region, age)) %>%
    tidytable::drop_na() %>% 
    tidytable::summarise(sd_l = mean(sd_l1),
                         cv_l = mean(cv_l), .by = c(species_code, sex, region)) %>% 
    tidytable::filter(sex != 3) %>% 
    tidytable::mutate(comp_type = case_when (sex == 1 ~ 'male',
                                             sex == 2 ~ 'female')) %>% 
    tidytable::select(-sex) %>% 
    tidytable::bind_rows(specimen %>% 
                           tidytable::drop_na() %>% 
                           tidytable::summarise(sd_l1 = sd(length),
                                                cv_l = sd(length) / mean(length), .by = c(species_code, region, age)) %>%
                           tidytable::drop_na() %>% 
                           tidytable::summarise(sd_l = mean(sd_l1),
                                                cv_l = mean(cv_l), .by = c(species_code, region)) %>% 
                           tidytable::mutate(comp_type = 'total')) -> sd_l
  
  err_iss %>% 
    tidytable::left_join(samp_dat) %>% 
    tidytable::left_join(ape) %>% 
    tidytable::left_join(sd_l) %>% 
    vroom::vroom_write(.,
                       here::here('output', 'afsc_iss_err_full.csv'),
                       delim = ',') -> plot_dat
} else{
  spec <- vroom::vroom(here::here('data', 'species_code_name.csv')) # species_code and common names
    plot_dat <- vroom::vroom(here::here('output', 'afsc_iss_err_full.csv'))
}

surv_labs <- c("Aleutian Isalnds", "Eastern Bering Sea Shelf", "Gulf of Alaska")
names(surv_labs) <- c("ai", "bs", "goa")

# clean up names to make nice for plotting
plot_dat %>% 
  tidytable::mutate(comp_type = case_when(comp_type == 'female' ~ 'Female',
                                          comp_type == 'male' ~ 'Male',
                                          comp_type == 'total' ~ 'Total')) -> plot_dat


# plot relative iss with added error for sex category by species type, 1 cm and pooled (figure 2) ----

png(filename = here::here("figs", "sex_iss.png"), 
    width = 6.5, height = 5.0,
    units = "in", res = 200)

plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Pooled') %>%
  select(year, species_code, comp_type, ae, ae_al, al, base) %>% 
  tidytable::mutate(ae_rel = ae / base,
                    ae_al_rel = ae_al / base,
                    al_rel = al / base,
                    base_rel = 1) %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base,
                                   ae_rel, ae_al_rel, al_rel, base_rel)) %>%
  tidytable::mutate(err_src = case_when(name %in% c('ae', 'ae_rel') ~ 'AE',
                                        name %in% c('al', 'al_rel') ~ 'GV',
                                        name %in% c('ae_al', 'ae_al_rel') ~ 'AE & GV',
                                        name %in% c('base', 'base_rel') ~ 'Base'),
                    iss_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base') ~ 'Age composition ISS',
                                         name %in% c('ae_rel', 'ae_al_rel', 'al_rel', 'base_rel') ~ 'Relative age composition ISS'),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>%
  tidytable::left_join(spec) %>%
  tidytable::filter(species_type != "other") %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, 
                width = 0.9,
                position = position_dodge(preserve = "single"),
                alpha = 0.5) +
  facet_grid(iss_type ~ species_type,
             scales = "free_y",
             labeller = label_wrap_gen(20),
             switch = "y") +
  ylab("\n") +
  xlab("\nAge composition sex category") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario") +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 270),
        strip.placement = "outside",
        strip.text = element_text(size = 12))


dev.off()


# compare pooled vs annual growth for 1 cm bins (figure 3), avg across sex categories ----

png(filename = here::here("figs", "grwth_iss.png"), 
    width = 6.5, height = 5.0,
    units = "in", res = 200)

plot_dat %>% 
  tidytable::filter(bin == '1cm') %>%
  tidytable::mutate(ae_rel = ae / base,
                    ae_al_rel = ae_al / base,
                    al_rel = al / base,
                    base_rel = 1) %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base, 
                                   ae_rel, ae_al_rel, al_rel, base_rel)) %>%
  tidytable::mutate(err_src = case_when(name %in% c('ae', 'ae_ann', 'ae_rel', 'ae_ann_rel') ~ 'AE',
                                        name %in% c('al', 'al_ann', 'al_rel', 'al_ann_rel') ~ 'GV',
                                        name %in% c('ae_al', 'ae_al_ann', 'ae_al_rel', 'ae_al_ann_rel') ~ 'AE & GV',
                                        name %in% c('base', 'base_ann','base_rel', 'base_ann_rel') ~ 'Base'),
                    iss_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base',
                                                     'ae_ann', 'ae_al_ann', 'al_ann', 'base_ann') ~ 'Age composition ISS',
                                         name %in% c('ae_rel', 'ae_al_rel', 'al_rel', 'base_rel',
                                                     'ae_ann_rel', 'ae_al_ann_rel', 'al_ann_rel', 'base_ann_rel') ~ 'Relative age composition ISS'),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  tidytable::filter(comp_type == 'Total') %>% 
  # tidytable::summarise(value = mean(value), .by = c(year, species_code, name, grwth, err_src, iss_type)) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::filter(species_type != 'other') %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  ggplot(aes(grwth, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(iss_type ~ species_type, 
             scales = "free_y",
             labeller = label_wrap_gen(20),
             switch = "y") +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 270),
        strip.placement = "outside",
        strip.text = element_text(size = 12)) +
  xlab("\nGrowth data treatment") +
  ylab("\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")

dev.off()

# compare bin sizes for annual growth (figure 4) ----

png(filename = here::here("figs", "bin_iss.png"), 
    width = 6.5, height = 5.0,
    units = "in", res = 200)

plot_dat %>% 
  tidytable::filter(grwth == 'Annual') %>%
  tidytable::mutate(ae_rel = ae / base,
                    ae_al_rel = ae_al / base,
                    al_rel = al / base,
                    base_rel = 1) %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base, 
                                   ae_rel, ae_al_rel, al_rel, base_rel)) %>%
  tidytable::mutate(err_src = case_when(name %in% c('ae', 'ae_rel', 'ae_2cm', 'ae_2cm_rel', 'ae_5cm', 'ae_5cm_rel') ~ 'AE',
                                        name %in% c('al', 'al_rel', 'al_2cm', 'al_2cm_rel', 'al_5cm', 'al_5cm_rel') ~ 'GV',
                                        name %in% c('ae_al', 'ae_al_rel', 'ae_al_2cm', 'ae_al_2cm_rel', 'ae_al_5cm', 'ae_al_5cm_rel') ~ 'AE & GV',
                                        name %in% c('base', 'base_rel', 'base_2cm', 'base_2cm_rel', 'base_5cm', 'base_5cm_rel') ~ 'Base'),
                    iss_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base',
                                                     'ae_2cm', 'ae_al_2cm', 'al_2cm', 'base_2cm',
                                                     'ae_5cm', 'ae_al_5cm', 'al_5cm', 'base_5cm') ~ 'Age composition ISS',
                                         name %in% c('ae_rel', 'ae_al_rel', 'al_rel', 'base_rel',
                                                     'ae_2cm_rel', 'ae_al_2cm_rel', 'al_2cm_rel', 'base_2cm_rel',
                                                     'ae_5cm_rel', 'ae_al_5cm_rel', 'al_5cm_rel', 'base_5cm_rel') ~ 'Relative age composition ISS'),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  tidytable::summarise(value = mean(value), .by = c(year, species_code, name, bin, err_src, iss_type)) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  ggplot(aes(bin, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(iss_type ~ species_type, 
             scales = "free_y",
             labeller = label_wrap_gen(20),
             switch = "y") +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 270),
        strip.placement = "outside",
        strip.text = element_text(size = 12)) +
  xlab("\nLength bin treatment") +
  ylab("\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")

dev.off()


# compare pre/post aggregation for 1cm bin & annual(figure 5) ----

png(filename = here::here("figs", "prepost_iss.png"), 
    width = 6.5, height = 5.0,
    units = "in", res = 200)

plot_dat %>% 
  tidytable::filter(species_code %in% c(21720, 30060) & 
                      bin == '1cm' & grwth == 'Annual' & 
                      comp_type == 'Total' & 
                      region == 'goa') %>% 
  tidytable::select(year, species_code, comp_type, ae, ae_al, al, base, bin, grwth) %>% 
  tidytable::left_join(vroom::vroom(here::here('output', 'popoll_prepost_iss_ag.csv')) %>% 
                         tidytable::rename(ae_pre = 'ae',
                                           ae_al_pre = 'ae_al',
                                           al_pre = 'al',
                                           base_pre = 'base') %>% 
                         tidytable::mutate(comp_type = case_when(comp_type == 'female' ~ 'Female',
                                                                 comp_type == 'male' ~ 'Male',
                                                                 comp_type == 'total' ~ 'Total'))) %>% 
  tidytable::mutate(ae_rel = ae / base,
                    ae_al_rel = ae_al / base,
                    al_rel = al / base,
                    base_rel = 1,
                    ae_pre_rel = ae_pre / base_pre,
                    ae_al_pre_rel = ae_al_pre / base_pre,
                    al_pre_rel = al_pre / base_pre,
                    base_pre_rel = 1) %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base, 
                                   ae_pre, ae_al_pre, al_pre, base_pre,
                                   ae_rel, ae_al_rel, al_rel, base_rel, 
                                   ae_pre_rel, ae_al_pre_rel, al_pre_rel, base_pre_rel)) %>%
  tidytable::mutate(pool_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base',
                                                      'ae_rel', 'ae_al_rel', 'al_rel', 'base_rel') ~ 'Post-expansion',
                                          name %in% c('ae_pre', 'ae_al_pre', 'al_pre', 'base_pre',
                                                      'ae_pre_rel', 'ae_al_pre_rel', 'al_pre_rel', 'base_pre_rel') ~ 'Pre-expansion'),
                    err_src = case_when(name %in% c('ae', 'ae_pre', 'ae_rel', 'ae_pre_rel') ~ 'AE',
                                        name %in% c('al', 'al_pre', 'al_rel', 'al_pre_rel') ~ 'GV',
                                        name %in% c('ae_al', 'ae_al_pre', 'ae_al_rel', 'ae_al_pre_rel') ~ 'AE & GV',
                                        name %in% c('base', 'base_pre', 'base_rel', 'base_pre_rel') ~ 'Base'),
                    iss_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base',
                                                     'ae_pre', 'ae_al_pre', 'al_pre', 'base_pre') ~ 'Age composition ISS',
                                         name %in% c('ae_rel', 'ae_al_rel', 'al_rel', 'base_rel',
                                                     'ae_pre_rel', 'ae_al_pre_rel', 'al_pre_rel', 'base_pre_rel') ~ 'Relative age composition ISS'),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>%
  tidytable::left_join(spec) %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  tidytable::mutate(stock = paste0(species_type, " (GOA ", species_name, ")")) %>% 
  ggplot(aes(pool_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(iss_type ~ stock, 
             scales = "free_y",
             labeller = label_wrap_gen(20),
             switch = "y") +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 270),
        strip.text = element_text(size = 12),
        strip.placement = "outside") +
  xlab("\nAggregation treatment") +
  ylab("") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")

dev.off() 




# plot caal results (figure 6) ----

png(filename = here::here("figs", "caal_iss.png"), 
    width = 6.5, height = 7.0,
    units = "in", res = 200)

vroom::vroom(here::here('output', 'goa_caal_iss_ag.csv')) %>% 
  tidytable::summarise(ae_caal = mean(ae, na.rm = TRUE),
                       al_caal = mean(al, na.rm = TRUE),
                       ae_al_caal = mean(ae_al, na.rm = TRUE),
                       base_caal = mean(base, na.rm = TRUE), .by = c(year, species_code, comp_type)) %>% 
  tidytable::mutate(ae_rel_caal = ae_caal / base_caal,
                    ae_al_rel_caal = ae_al_caal / base_caal,
                    al_rel_caal = al_caal / base_caal,
                    base_rel_caal = 1,
                    comp_type = case_when(comp_type == 'female' ~ 'Female',
                                          comp_type == 'male' ~ 'Male',
                                          comp_type == 'total' ~ 'Total')) %>% 
  tidytable::full_join(plot_dat %>% 
                         tidytable::filter(species_code %in% c(10110, 21720, 30060) & bin == '1cm' & grwth == 'Annual' & region == 'goa') %>% 
                         tidytable::select(year, species_code, comp_type, ae, ae_al, al, base) %>%
                         tidytable::mutate(ae_rel = ae / base,
                                           ae_al_rel = ae_al / base,
                                           al_rel = al / base,
                                           base_rel = 1)) %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base,
                                   ae_rel, ae_al_rel, al_rel, base_rel,
                                   ae_caal, ae_al_caal, al_caal, base_caal,
                                   ae_rel_caal, ae_al_rel_caal, al_rel_caal, base_rel_caal)) %>% 
  tidytable::mutate(err_src = case_when(name %in% c('ae', 'ae_rel', 'ae_caal', 'ae_rel_caal') ~ 'AE',
                                        name %in% c('al', 'al_rel', 'al_caal', 'al_rel_caal') ~ 'GV',
                                        name %in% c('ae_al', 'ae_al_rel', 'ae_al_caal', 'ae_al_rel_caal') ~ 'AE & GV',
                                        name %in% c('base', 'base_rel', 'base_caal', 'base_rel_caal') ~ 'Base'),
                    iss_type = case_when(name %in% c('ae', 'ae_al', 'al', 'base') ~ 'Age composition ISS',
                                         name %in% c('ae_rel', 'ae_al_rel', 'al_rel', 'base_rel') ~ 'Relative age composition ISS',
                                         name %in% c('ae_caal', 'ae_al_caal', 'al_caal', 'base_caal') ~ 'Conditional age-at-length ISS',
                                         name %in% c('ae_rel_caal', 'ae_al_rel_caal', 'al_rel_caal', 'base_rel_caal') ~ 'Relative conditional age-at-length ISS'),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  tidytable::mutate(stock = paste0(species_type, " (GOA ", species_name, ")")) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(iss_type ~ stock, 
             scales = "free_y",
             labeller = label_wrap_gen(20),
             switch = "y") +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 270),
        strip.placement = "outside",
        strip.text = element_text(size = 12)) +
  xlab("\nAge composition sex category") +
  ylab("\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")

dev.off()




# plot iss and nss with added error (figure 7) ----

plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, nhls, nss, region) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  tidytable::mutate(ae_ss = ae / nss,
                    al_ss = al / nss,
                    ae_al_ss = ae_al / nss,
                    base_ss = base / nss) %>% 
  tidytable::pivot_longer(cols = c(ae_ss, al_ss, ae_al_ss, base_ss)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae_ss' ~ 'AE',
                                        name == 'al_ss' ~ 'GV',
                                        name == 'ae_al_ss' ~ 'AE & GV',
                                        name == 'base_ss' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "eastern Bering Sea shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV')),
                    surv_labs = factor(surv_labs)) %>% 
  tidytable::filter(species_type != 'other') %>% 
  ggplot(aes(nss, value, color = err_src)) +
  geom_point(alpha = 0.3) +
  facet_grid( ~ species_type,
              labeller = labeller(region = surv_labs)) +
  xlab("\nNumber of age samples") +
  ylab("Age composition ISS\n") +
  labs(pch = "Stock") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") +
  theme(legend.position = "none") + 
  geom_smooth(method = 'lm',
              formula = y ~ x) +
  ggpmisc::stat_poly_eq(label.x = "right",
                        label.y = "top", 
                        formula = y ~ x,
                        parse = TRUE) -> p1

plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, nhls, nss, region) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::mutate(ae_ss = ae / nss,
                    al_ss = al / nss,
                    ae_al_ss = ae_al / nss,
                    base_ss = base / nss) %>% 
  tidytable::pivot_longer(cols = c(ae_ss, al_ss, ae_al_ss, base_ss)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae_ss' ~ 'AE',
                                        name == 'al_ss' ~ 'GV',
                                        name == 'ae_al_ss' ~ 'AE & GV',
                                        name == 'base_ss' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "eastern Bering Sea shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV')),
                    surv_labs = factor(surv_labs)) %>% 
  tidytable::filter(species_type != 'other') %>% 
  ggplot(aes(err_src, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid( ~ species_type) +
  xlab("\nUncertainty scenario") +
  ylab("Age composition ISS per age sample") +
  scale_color_scico_d(palette = 'roma') + 
  scale_fill_scico_d(palette = 'roma', alpha = 0.5) + 
  theme(legend.position = "none",
        strip.text = element_text(size = 0)) -> p2

ggpubr::ggarrange(p1 + ggpubr::rremove("ylab"),
                  p2 + ggpubr::rremove("ylab"),
                  ncol= 1) -> fig

png(filename = here::here("figs", "iss_vs_nss.png"), 
    width = 6.5, height = 7.0,
    units = "in", res = 200)

ggpubr::annotate_figure(fig, 
                        left = grid::textGrob("Age composition ISS per age sample\n", 
                                              rot = 90, vjust = 0.5, 
                                              gp = grid::gpar(cex = 1, fontface="plain", fontfamily="Times New Roman")))

dev.off()



# plot iss and hauls with added error (figure 8) ----

plot_dat %>%
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, nhls, nss, region) %>%
  tidytable::left_join(spec) %>%
  tidytable::mutate(ae_hl = ae / nhls,
                    al_hl = al / nhls,
                    ae_al_hl = ae_al / nhls,
                    base_hl = base / nhls,
                    n_hl = nss/ nhls) %>%
  tidytable::pivot_longer(cols = c(ae_hl, al_hl, ae_al_hl, base_hl)) %>%
  tidytable::mutate(err_src = case_when(name == 'ae_hl' ~ 'AE',
                                        name == 'al_hl' ~ 'GV',
                                        name == 'ae_al_hl' ~ 'AE & GV',
                                        name == 'base_hl' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "eastern Bering Sea shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV')),
                    surv_labs = factor(surv_labs)) %>%
  tidytable::filter(species_type != 'other') -> hls_dat

hls_dat %>%
  ggplot(aes(n_hl, value, color = err_src)) +
  geom_point(alpha = 0.3) +
  geom_abline(slope = 1, intercept = 0, lty=3) +
  facet_grid( ~ species_type,
              labeller = labeller(region = surv_labs)) +
  xlab("\nNumber of age samples per sampled haul") +
  ylab("Age composition input sample size per sampled haul\n") +
  labs(pch = "Stock") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") +
  theme(legend.position = "none") +
  geom_smooth(method = 'lm',
              formula = y ~ x) +
  ggpmisc::stat_poly_eq(label.x = "left",
                        label.y = "top",
                        formula = y ~ x,
                        parse = TRUE) -> p1

hls_dat %>%
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>% 
  tidytable::drop_na() %>%
  ggplot(aes(err_src, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid( ~ species_type) +
  xlab("\nUncertainty scenario") +
  ylab("Age composition input sample size per sampled haul") +
  scale_color_scico_d(palette = 'roma') +
  scale_fill_scico_d(palette = 'roma', alpha = 0.5) +
  theme(legend.position = "none") -> p2

ggpubr::ggarrange(p1 + ggpubr::rremove("ylab"),
                  p2 + ggpubr::rremove("ylab"),
                  ncol= 1) -> fig


png(filename=here::here("figs", "iss_vs_nss_hls.png"),
    width = 6.5, height = 7.0,
    units = "in", res=200)

ggpubr::annotate_figure(fig,
                        left = grid::textGrob("Age composition ISS per sampled haul\n",
                                              rot = 90, vjust = 0.5,
                                              gp = grid::gpar(cex = 1, fontface="plain", fontfamily="Times New Roman")))

dev.off()



# plot relationship with life history (figure 9) ----

plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>%
  tidytable::left_join(spec) %>%
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  tidytable::mutate(prop_ae = ae / base,
                    prop_al = al / base,
                    prop_ae_al = ae_al / base) %>% 
  tidytable::pivot_longer(cols = c(prop_ae, prop_ae_al, prop_al)) %>% 
  tidytable::mutate(err_src = case_when(name == 'prop_ae' ~ 'AE',
                                        name == 'prop_al' ~ 'GV',
                                        name == 'prop_ae_al' ~ 'AE & GV'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src)) %>% 
  tidytable::filter(err_src == 'AE', species_type != 'other') %>% 
  ggplot(.,aes(x = age_range, y = value, color = as.factor(species_type))) +
  geom_point(alpha = 0.3) +
  xlab("Age range (years)") +
  ylab("AE") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") + 
  theme(text = element_text(size = 10),
        legend.position = "none") + 
  geom_smooth(method = 'lm',
              formula = y ~ x) -> p1


plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual' & species_code != 30420) %>%
  tidytable::left_join(spec) %>%
  tidytable::mutate(prop_ae = ae / base,
                    prop_al = al / base,
                    prop_ae_al = ae_al / base) %>% 
  tidytable::pivot_longer(cols = c(prop_ae, prop_ae_al, prop_al)) %>% 
  tidytable::mutate(err_src = case_when(name == 'prop_ae' ~ 'AE',
                                        name == 'prop_al' ~ 'GV',
                                        name == 'prop_ae_al' ~ 'AE & GV'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src)) %>% 
  tidytable::filter(err_src == 'GV', species_type != 'other') %>% 
  ggplot(.,aes(x = len_range, y = value, color = as.factor(species_type))) +
  geom_point(alpha = 0.3) +
  xlab("Length range (cm)") +
  ylab("GV") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") + 
  theme(text = element_text(size = 10),
        legend.position = "none") + 
  geom_smooth(method = 'lm',
              formula = y ~ x) -> p2

plot_dat %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>%
  tidytable::left_join(spec) %>%
  tidytable::mutate(species_type = case_when(species_type == 'flatfish' ~ 'Flatfish',
                                             species_type == 'rockfish' ~ 'Rockfish',
                                             species_type == 'gadid' ~ 'Gadid')) %>% 
  tidytable::mutate(prop_ae = ae / base,
                    prop_al = al / base,
                    prop_ae_al = ae_al / base) %>% 
  tidytable::pivot_longer(cols = c(prop_ae, prop_ae_al, prop_al)) %>% 
  tidytable::mutate(err_src = case_when(name == 'prop_ae' ~ 'AE',
                                        name == 'prop_al' ~ 'GV',
                                        name == 'prop_ae_al' ~ 'AE & GV'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src)) %>% 
  tidytable::filter(err_src == 'AE & GV', species_type != 'other') %>% 
  tidytable::summarise(mean_ae = mean(value, na.rm = TRUE),
                       lci_hl = quantile(value, probs = 0.025, na.rm = TRUE),
                       uci_hl = quantile(value, probs = 0.975, na.rm = TRUE), 
                       .by = c(species_type)) %>% 
  ggplot(aes(reorder(species_type, -mean_ae), mean_ae, fill = species_type)) +
  geom_bar(stat = "identity", alpha = 0.5) +
  geom_errorbar(aes(x = reorder(species_type, mean_ae), 
                    ymin = lci_hl, ymax = uci_hl), 
                width = 0) +
  scale_fill_scico_d(palette = 'roma',
                     name = "") + 
  theme(axis.text.x = element_text(angle = -45, hjust = 0),
        axis.title.x = element_blank(),
        legend.position = "none") +
  ylab("AE & GV") +
  ylim(0, 1.3) -> p3

ggpubr::ggarrange(ggpubr::ggarrange(p1, p2, ncol = 2),
                  p3,
                  nrow = 2) -> fig

png(filename = here::here("figs", "lh_iss.png"),
    width = 6.5, height = 6.0,
    units = "in", res = 200)

ggpubr::annotate_figure(fig, 
                        left = grid::textGrob("Relative age composition ISS\n", 
                                              rot = 90, vjust = 1, 
                                              gp = grid::gpar(cex = 1, fontface="plain", fontfamily="Times New Roman")))

dev.off()





# supplementary material figures ----


# plot age iss with added error for all species-regions, pooled growth, 1 cm bins ----

png(filename=here::here("figs", "supp_mat", "pooled_1cm_iss.png"), 
    width = 6.5, height = 8.0,
    units = "in", res=200)

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region, bin, grwth) %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Pooled') %>% 
  tidytable::left_join(spec) %>%
  tidytable::filter(species_type != 'other') %>% 
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae' ~ 'AE',
                                        name == 'al' ~ 'GV',
                                        name == 'ae_al' ~ 'AE & GV',
                                        name == 'base' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  # filter(species_name %in% c("Arrowtooth flounder", "Pacific ocean perch", "Pacific cod", "Walleye pollock")) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(species_name ~ surv_labs, 
             scales = "free_y",
             labeller = label_wrap_gen(10)) +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 0)) +
  xlab("\nAge composition sex category") +
  ylab("Age composition ISS\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")  +
  scale_y_continuous(breaks = c(0, 250, 500)) +
  expand_limits(y=c(0, 250))
# scale_y_continuous(breaks  = c(0, 200, 00))

dev.off() 

# plot age iss with added error for all species-regions, annual growth, 1 cm bins ----

png(filename=here::here("figs", "supp_mat", "annual_1cm_iss.png"), 
    width = 6.5, height = 8.0,
    units = "in", res=200)

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region, bin, grwth) %>% 
  tidytable::filter(bin == '1cm' & grwth == 'Annual') %>% 
  tidytable::left_join(spec) %>%
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae' ~ 'AE',
                                        name == 'al' ~ 'GV',
                                        name == 'ae_al' ~ 'AE & GV',
                                        name == 'base' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  # filter(species_name %in% c("Arrowtooth flounder", "Pacific ocean perch", "Pacific cod", "Walleye pollock")) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(species_name ~ surv_labs, 
             scales = "free_y",
             labeller = label_wrap_gen(10)) +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 0)) +
  xlab("\nAge composition sex category") +
  ylab("Age composition ISS\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")  +
  scale_y_continuous(breaks = c(0, 250, 500)) +
  expand_limits(y=c(0, 250))
# scale_y_continuous(breaks  = c(0, 200, 00))

dev.off() 


# plot age iss with added error for all species-regions, annual growth, 2 cm bins ----

png(filename=here::here("figs", "supp_mat", "annual_2cm_iss.png"), 
    width = 6.5, height = 8.0,
    units = "in", res=200)

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region, bin, grwth) %>% 
  tidytable::filter(bin == '2cm' & grwth == 'Annual') %>% 
  tidytable::left_join(spec) %>%
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae' ~ 'AE',
                                        name == 'al' ~ 'GV',
                                        name == 'ae_al' ~ 'AE & GV',
                                        name == 'base' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  # filter(species_name %in% c("Arrowtooth flounder", "Pacific ocean perch", "Pacific cod", "Walleye pollock")) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(species_name ~ surv_labs, 
             scales = "free_y",
             labeller = label_wrap_gen(10)) +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 0)) +
  xlab("\nAge composition sex category") +
  ylab("Age composition ISS\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")  +
  scale_y_continuous(breaks = c(0, 250, 500)) +
  expand_limits(y=c(0, 250))
# scale_y_continuous(breaks  = c(0, 200, 00))

dev.off() 


# plot age iss with added error for all species-regions, annual growth, 5 cm bins ----

png(filename=here::here("figs", "supp_mat", "annual_5cm_iss.png"), 
    width = 6.5, height = 8.0,
    units = "in", res=200)

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region, bin, grwth) %>% 
  tidytable::filter(bin == '5cm' & grwth == 'Annual') %>% 
  tidytable::left_join(spec) %>%
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae' ~ 'AE',
                                        name == 'al' ~ 'GV',
                                        name == 'ae_al' ~ 'AE & GV',
                                        name == 'base' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Eastern Bering Sea Shelf"),
                    err_src = factor(err_src, level = c('Base', 'AE', 'GV', 'AE & GV'))) %>% 
  # filter(species_name %in% c("Arrowtooth flounder", "Pacific ocean perch", "Pacific cod", "Walleye pollock")) %>% 
  ggplot(aes(comp_type, value, fill = err_src)) +
  geom_boxplot2(width.errorbar = 0, alpha= 0.5) +
  facet_grid(species_name ~ surv_labs, 
             scales = "free_y",
             labeller = label_wrap_gen(10)) +
  theme(legend.position = "bottom",
        strip.text.y.right = element_text(angle = 0)) +
  xlab("\nAge composition sex category") +
  ylab("Age composition ISS\n") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Uncertainty scenario")  +
  scale_y_continuous(breaks = c(0, 250, 500)) +
  expand_limits(y=c(0, 250))
# scale_y_continuous(breaks  = c(0, 200, 00))

dev.off() 









